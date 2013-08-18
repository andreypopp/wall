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
{validateBody}                        = require 'schematron/lib/middleware'
passport                              = require 'passport'
{queryRow, queryRows, withDB, items}  = require './db'

rel = path.join.bind(null, __dirname)

promise = (func) ->
  (req, res, next) ->
    func(req, res, next)
      .then (result) ->
        if result == undefined then res.send 404 else res.send result
      .fail(next)
      .end()

authOnly = (req, res, next) ->
  unless req.user
    res.send 401
  else
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

  app = express()
  app.use express.bodyParser()
  app.use withDB(options.database)

  app.get '/items', promise (req, res) ->
    q = "select * from items where parent is null order by created desc"
    queryRows(req.conn, q).then (items) -> {items}

  app.post '/items', authOnly, promise (req, res) ->
    data = req.body or {}
    data.creator = req.user.id
    q = items.insert(data).returning(items.star())
    queryRow(req.conn, q)

  app.get '/items/:id', promise (req, res) ->
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
      for item in items
        mapping[item.id] = item
        parent = mapping[item.parent]
        (parent.comments or= []).push(item) if parent

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
