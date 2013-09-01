express       = require 'express'
passport      = require 'passport'

authenticated = (req, res, next) ->
  unless req.user then res.send 401 else next()

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

module.exports = (options = {}) ->
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

module.exports.authenticated = authenticated
