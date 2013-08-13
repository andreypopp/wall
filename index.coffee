###

  Application entry point

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

{extend}    = require 'underscore'
path        = require 'path'
sqlite      = require 'sqlite3'
kew         = require 'kew'
uuid        = require 'node-uuid'
express     = require 'express'
page        = require 'connect-page'
stylus      = require 'connect-stylus'
browserify  = require 'connect-browserify'
passport    = require 'passport'

rel = path.join.bind(null, __dirname)

promise = (func) ->
  (req, res, next) ->
    func(req, res, next)
      .then (result) ->
        if result == undefined then res.send 404 else res.send result
      .fail(next)
      .end()

promisify = (func) ->
  (args...) ->
    result = kew.defer()
    args.push (err, res) ->
      if err then result.reject(err) else result.resolve(res)
    func.call(this, args...)
    result

asParams = (o) ->
  result = {}
  for k, v of o
    result["$#{k}"] = v.toString()
  result

authOnly = (req, res, next) ->
  unless req.user
    res.send 401
  else
    next()

sqlite.Database::promiseRun = promisify sqlite.Database::run
sqlite.Database::promiseAll = promisify sqlite.Database::all
sqlite.Database::promiseGet = promisify sqlite.Database::get

assets = (options = {}) ->
  app = express()
  app.get '/css/index.css', stylus
    entry: rel 'ui/index.styl'
    use: ['normalize', 'nib']
    includeCSS: true
  app.get '/js/index.js', browserify
    entry: rel 'ui/index.coffee'
    extensions: ['.coffee']
    transforms: ['coffeeify', 'reactify']
    debug: true
  app.use '/font', express.static rel('node_modules/font-awesome/font')
  app

api = (options = {}) ->
  db = new sqlite.Database(options.database or ':memory:')

  db.run """
    create table if not exists items (
      id text,
      title text,
      uri text,
      description text,
      created text,
      creator text,
      parent text,
      primary key (id)
    );
    """

  getCommentsFor = (item) ->
    item = extend {}, item
    db.promiseAll("select * from items where parent = $id", item.id)
      .then (comments) ->
        kew.all comments.map getCommentsFor
      .then (comments) ->
        item.comments = comments
        item

  app = express()

  app.get '/items', promise (req, res) ->
    db.promiseAll("select * from items where parent is null order by created desc")
      .then (items) -> {items}

  app.post '/items', authOnly, promise (req, res) ->
    data = req.body
    data.id = uuid.v4()
    data.created = new Date
    data.creator = req.user.id
    db.promiseRun("""
      insert into items (id, title, uri, description, created, creator, parent)
      values ($id, $title, $uri, $description, $created, $creator, $parent)
      """, asParams(data)).then ->
          data.comments = []
          data

  app.get '/items/:id', promise (req, res) ->
    db.promiseGet("select * from items where id = $id", req.params.id)
      .then getCommentsFor

  app.get '/users/:username', (req, res) ->
    res.send
      username: req.params.username

  app

auth = (options = {}) ->

  storeIdentity = (accessToken, refreshToken, profile, cb) ->
    user =
      id: "#{profile.username}@#{profile.provider}"
      displayName: profile.displayName
    cb(null, user)

  authenticate = (req, res, next) ->
    provider = passport.authenticate req.params.provider
    provider(req, res, next)

  setUser = (user) ->
    window.localStorage.setItem('wall.user', JSON.stringify(user))

  callInBrowser = (func, args...) ->
    """
    <!doctype html>
    <script>
    (#{func.toString()})(#{args.map(JSON.stringify).join(', ')});
    window.close();
    </script>
    """

  passport.serializeUser (user, done) ->
    done(null, user)

  passport.deserializeUser (user, done) ->
    done(null, user)

  for provider, providerOptions of options
    strategy = require("passport-#{provider}").Strategy
    passport.use new strategy(providerOptions, storeIdentity)

  app = express()

  app.get '/logout', (req, res) ->
    req.logOut()
    res.send callInBrowser setUser, null
  app.get '/:provider', authenticate
  app.get '/:provider/callback', authenticate, (req, res) ->
    res.send callInBrowser setUser, req.user

  app

module.exports = (options = {}) ->
  app = express()
  app.use express.logger('dev')
  app.use express.favicon()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.cookieSession(secret: options?.secret)
  app.use passport.initialize()
  app.use passport.session()
  app.use '/auth', auth(options?.auth)
  app.use '/api', api(options)
  app.use '/a', assets(options)
  app.use page
    title: 'Wall'
    scripts: ['/a/js/index.js']
    stylesheets: ['/a/css/index.css']
    data:
      authProviders: Object.keys(options.auth)
  app.use express.errorHandler()
  app
