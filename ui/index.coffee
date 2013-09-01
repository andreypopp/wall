###*

  UI entry point

  @jsx React.DOM

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

Backbone                      = require 'backbone'
BackboneQueryParameters       = require 'backbone-query-parameters'
Backbone.$                    = require 'jqueryify'
React                         = require 'react-tools/build/modules/React'
DOMEvents                     = require 'react-dom-events'
Control                       = require './control'
HasModal                      = require './modal'
{AppEvents, LocationAware,
  UserAware}                  = require './utils'
Dropdown                      = require './dropdown'
{Item, Items}                 = require '../models'
_BootstrapModal               = require './bootstrap-modal'
router                        = require './router'
SubmitDialog                  = require './submit'
ItemScreen                    = require './item_screen'
ItemsScreen                   = require './items_screen'

App = React.createClass
  mixins: [AppEvents, DOMEvents, LocationAware, UserAware, HasModal]

  propTypes:
    title: React.PropTypes.string.isRequired

  routes:
    '':               'items'
    'items/:id':      'item'
    '~:username':     'user'
    'auth/:provider': 'auth'

  events:
    'click a': 'onClick'
    'touchstart a': 'onClick'

  onClick: (e) ->
    href = e.currentTarget.attributes?.href?.value
    if href? and not /https?:/.exec href
      e.preventDefault()
      this.router.navigate href, trigger: true

  getInitialState: ->
    {user: this.getUser()}

  componentDidMount: ->
    this.listenTo this.router, 'route:items', (params) =>
      model = new Items(params)
      model.fetch().then => this.show new ItemsScreen({model}), suppressNavigation: true
    this.listenTo this.router, 'route:item', (id) =>
      model = new Item {id}
      model.fetch().then => this.show new ItemScreen({model}), suppressNavigation: true
    this.listenTo this.router, 'route:auth', (provider) =>
      window.open(window.location.pathname)
      Backbone.history.history.back()

  show: (screen, options = {}) ->
    window.scrollTo(0)
    this.setState {screen}
    screenURL = screen.url()
    unless options.suppressNavigation
      this.router.navigate screenURL, {trigger: options.trigger} if screenURL?

  renderControls: ->
    controls = if this.getUser()?
      [Control(
        class: 'submit', icon: 'pencil', label: 'Submit', tabIndex: 3,
        onClick: => this.showModal SubmitDialog()),
       Control(
        class: 'logout', icon: 'signout', tabIndex: 4,
        href: '/auth/logout', label: 'Sign out')]
    else
      `<Dropdown class="login" icon="signin" label="Sign in">
        <Control href="/auth/facebook" label="with Facebook" icon="facebook" />
       </Dropdown>`
    `<div class="Controls">{controls}</div>`

  render: ->
    screen = this.state?.screen
    `<div class="App">
      <header>
        <h1 class="title"><Control tabIndex="2" href="/" label={this.props.title} /></h1>
        {this.renderControls()}
      </header>
      <div class="screen">{screen}</div>
      {this.renderModal()}
     </div>`

window.onload = ->
  React.initializeTouchEvents(true)
  Wall = window.Wall = App(title: __data.title or 'wall')
  Wall.settings = __data
  React.renderComponent Wall, document.body
  Backbone.history.start(pushState: true)
