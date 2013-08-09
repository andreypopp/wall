###

  Application entry point

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

path        = require 'path'
express     = require 'express'
page        = require 'connect-page'
stylus      = require 'connect-stylus'
browserify  = require 'connect-browserify'

rel = path.join.bind(null, __dirname)

assets = ->
  app = express()
  app.get '/index.css', stylus
    entry: rel 'ui/index.styl'
    use: ['normalize', 'nib']
    includeCSS: true
  app.get '/index.js', browserify
    entry: rel 'ui/index.coffee'
    extensions: ['.coffee']
    transforms: ['coffeeify', 'reactify']
    debug: true
  app.use '/font', express.static rel('node_modules/font-awesome/font')
  app

module.exports = (options = {}) ->
  app = express()
  app.use express.logger('dev')
  app.use express.favicon()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.cookieSession(secret: 'x')
  app.get '/', page
    title: 'Wall'
    scripts: ['/a/index.js']
    stylesheets: ['/a/index.css']
  app.use '/a', assets()
  app.use express.errorHandler()
  app
