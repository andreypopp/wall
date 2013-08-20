###

  Application entry point

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

path                                  = require 'path'
{extend}                              = require 'underscore'
{all}                                 = require 'kew'
express                               = require 'express'
page                                  = require 'connect-page'
stylus                                = require 'connect-stylus'
browserify                            = require 'connect-browserify'
passport                              = require 'passport'
{begin, commit, rollback, connect,
  queryRow, queryRows, items} = require './db'
{Item}                                = require './models'

rel = path.join.bind(null, __dirname)

promise = (func) ->
  (req, res, next) ->
    func(req, res, next)
      .then (result) ->
        if result == undefined then res.send 404 else res.send result
      .fail(next)
      .end()

authOnly = (req, res, next) ->
  unless req.user then res.send 401 else next()

model = (modelClass) ->
  (req, res, next) ->
    try
      m = new modelClass(req.body, parse: true)
    catch e
      return next(e)
    unless m.isValid()
      res.send 400, m.validationError
    else
      req.model = m
      next()

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

  readingDB = (handler) -> (req, res, next) ->
    connect(options.database)
      .then (conn) ->
        req.conn = conn
        handler(req, res, next)
      .fin ->
        req.conn.release()

  writingDB = (handler) ->
    readingDB (req, res, next) ->
      begin(req.conn).then ->
        handler(req, res, next)
          .then (result) ->
            commit(req.conn).then -> result
          .fail (err) ->
            rollback(req.conn).then -> throw err

  app = express()
  app.use express.bodyParser()

  app.get '/items', promise readingDB (req, res) ->
    q = "select * from items where parent is null order by created desc"
    queryRows(req.conn, q).then (items) -> {items}

  app.post '/items', authOnly, model(Item), promise writingDB (req, res) ->
    data = req.body or {}
    data.creator = req.user.id
    q = items.insert(data).returning(items.star())
    queryRow(req.conn, q).then (item) ->
      item.comments = []
      item

  app.get '/items/:id', promise readingDB (req, res) ->
    itemQuery = "select * from items where id = $1"
    commentsQuery = """
      with recursive comments as (
        select items.* from items where parent = $1
          union
        select items.* from items join comments on comments.id = items.parent)
      select * from comments
    """

    deserializeTree = (root, items) ->
      mapping = {}
      mapping[root.id] = root
      root.comments = []
      for item in items
        item.comments = []
        mapping[item.id] = item
        parent = mapping[item.parent]
        parent.comments.push(item) if parent

    item = queryRow(req.conn, itemQuery, req.params.id)
    comments = queryRows(req.conn, commentsQuery, req.params.id)
    all(item, comments).then ([item, comments]) ->
      deserializeTree item, comments
      item

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

extend module.exports, {api, assets, auth}
