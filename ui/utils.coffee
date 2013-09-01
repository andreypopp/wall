Backbone          = require 'backbone'
{extend, result}  = require 'underscore'

AppEvents = extend {}, Backbone.Events,
  componentWillUnmount: ->
    this.stopListening()

LocationAware =
  componentDidMount: ->
    this.router = new Backbone.Router(routes: this.routes)

UserAware =
  USER_KEY: 'wall.user'

  getUser: ->
    try
      JSON.parse localStorage.getItem(this.USER_KEY)
    catch e
      null

  _handleStorageEvent: (e) ->
    this.setState(user: this.getUser()) if e.originalEvent.key == this.USER_KEY

  componentDidMount: ->
    window.addEventListener "storage", this._handleStorageEvent

  componentWillUnmount: ->
    window.removeEventListener "storage", this._handleStorageEvent

HasScreen =
  url: -> result this.props.model, 'screenURL'

animate = (node, animation) ->
  $node = $ node
  $node.one 'oanimationend animationend webkitAnimationEnd', ->
    $node.removeClass animation
  $node.addClass animation

module.exports = {HasScreen, UserAware, LocationAware, AppEvents, animate}
