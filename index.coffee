###

  Application entry point.

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

path                                  = require 'path'
{extend}                              = require 'underscore'
express                               = require 'express'
page                                  = require 'connect-page'
stylus                                = require 'connect-stylus'
browserify                            = require 'connect-browserify'
passport                              = require 'passport'
reactApp                              = require 'react-app'
{Item}                                = require './models'
auth                                  = require './auth'
api                                   = require './api'

rel = path.join.bind(null, __dirname)

assets = (options = {}) ->
  app = express()
  app.get '/css/index.css', stylus
    entry: rel 'ui/index.styl'
    use: ['normalize', 'nib']
    includeCSS: true
  app.get '/js/index.js', browserify
    entry: rel 'ui/index.coffee'
    extensions: ['.coffee']
    transforms: ['coffeeify', 'reactify/undoubted']
    debug: true
  app.use '/font', express.static rel('node_modules/font-awesome/font')
  app

module.exports = (options = {}) ->
  app = express()
  app.use express.logger('dev')
  app.use express.favicon()
  app.use express.cookieParser()
  app.use express.cookieSession(secret: options?.secret)
  app.use passport.initialize()
  app.use passport.session()
  app.use '/auth', auth(options?.auth)
  app.use '/api', api(options)
  app.use '/a', assets(options)
  app.use page
    title: options.title or 'wall'
    scripts: ['/a/js/index.js']
    stylesheets: ['/a/css/index.css']
    meta:
      viewport: 'width=device-width, user-scalable=no'
    data:
      title: options.title or 'wall'
      authProviders: Object.keys(options.auth)
  app.use express.errorHandler()
  app

extend module.exports, {api, assets, auth}
