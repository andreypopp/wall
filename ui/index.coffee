###*

  UI entry point

  @jsx React.DOM

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

{extend, result, isFunction}  = require 'underscore'
Backbone                      = require 'backbone'
Record                        = require 'backbone.record'
Backbone.$                    = require 'jqueryify'
React                         = require 'react-tools/build/modules/react'
Timestamp                     = require 'react-time'
DOMEvents                     = require 'react-dom-events'
_BootstrapModal               = require './bootstrap-modal'

AppEvents = extend {}, Backbone.Events,
  componentWillUnmount: ->
    this.stopListening()

LocationAware =
  componentDidMount: ->
    this.router = new Backbone.Router(routes: this.routes)

UserAware =
  getUser: ->
    try
      JSON.parse localStorage.getItem('wall.user')
    catch e
      null

  _handleStorageEvent: (e) ->
    this.forceUpdate() if e.key == 'wall.user'

  componentDidMount: ->
    Backbone.$(window).on "storage", this._handleStorageEvent

  componentWillUnmount: ->
    Backbone.$(window).off "storage", this._handleStorageEvent

HasModal =
  renderModal: ->
    if this.state?.modal
      `<Modal ref="modal"
        onHide={this.onModalHide}
        onClick={this.hideModal}>{this.state.modal}</Modal>` 

  onModalHide: ->
    this.setState(modal: undefined)

  showModal: (screen) ->
    this.setState(modal: screen)

  hideModal: ->
    this.refs.modal.hide()

Screen =
  url: -> result this.props.model, 'screenURL'

class User extends Record

class Item extends Record
  @define 'title', 'uri', 'description', 'created', 'creator'

  url: -> if this.id? then "/api/items/#{this.id}" else "/api/items"
  screenURL: -> if this.id? then "/items/#{this.id}"

class ItemCollection extends Backbone.Collection
  model: Item

class Items extends Record
  @define
    items: ItemCollection

  url: -> '/api/items'
  screenURL: -> '/'

Control = React.createClass
  render: ->
    iconClass = "icon icon-#{this.props.icon}"
    selfClass = "Control #{this.props.class or ''}"
    label = if this.props.label
      `<span class="label">{this.props.label}</span>`
    `<a onClick={this.props.onClick} class={selfClass} href={this.props.href}>
      <i class={iconClass}></i>{label}
     </a>`

ItemsScreen = React.createClass
  mixins: [Screen]
  propTypes:
    model: React.PropTypes.instanceOf(Items).isRequired
  render: ->
    items = this.props.model.items.map (item) => ItemView {item}
    `<div class="ItemsScreen">{items}</div>`

ItemView = React.createClass
  propTypes:
    item: React.PropTypes.instanceOf(Item).isRequired
  render: ->
    item = this.props.item
    `<div class="ItemView">
      <i class="icon icon-globe"></i>
      <h4 class="title"><a href={item.screenURL()}>{item.title}</a></h4>
      <a class="uri" href={item.uri}>{item.uri}</a>
      <Timestamp class="created" relative value={item.created} />
     </div>`

CommentEditor = React.createClass
  render: ->
    `<div class="CommentEditor">
      <i class="icon icon-comment"></i>
      <textarea ref="description" class="description" placeholder="Add comment"></textarea>
      <div class="Controls">
        <Control onClick={this.props.onSubmit} icon="ok" label="Submit" />
        <Control onClick={this.props.onCancel} icon="remove" label="Cancel" />
      </div>
     </div>`

ItemScreen = React.createClass
  mixins: [Screen]
  propTypes:
    model: React.PropTypes.instanceOf(Item).isRequired

  onAddComment: ->
    this.setState(commentEditorShown: true)

  onCommentCancel: ->
    this.setState(commentEditorShown: false)

  render: ->
    comments = if this.state?.commentEditorShown
      `<CommentEditor onCancel={this.onCommentCancel} />`
    else
      `<div class="Controls">
        <Control onClick={this.onAddComment} icon="comment" label="Add comment" />
       </div>`
    `<div class="ItemScreen">
      <ItemView item={this.props.model} />
      {comments}
     </div>`

WriteScreen = React.createClass
  mixins: [Screen]

  getInitialState: ->
    {model: new Item}

  onSubmit: (e) ->
    e.preventDefault()
    data = 
      title: this.refs.title.getDOMNode().value
      uri: this.refs.uri.getDOMNode().value
      description: this.refs.description.getDOMNode().value
    this.state.model.save(data).then =>
      Wall.show(new ItemScreen(model: this.state.model), trigger: true)
      Wall.hideModal()

  onCancel: ->
    Wall.hideModal()

  render: ->
    item = this.state.model
    `<div class="WriteScreen">
      <div class="form">
        <input type="text" class="title" ref="title" value={item.title} placeholder="Title" />
        <input type="text" class="uri" ref="uri" value={item.uri} placeholder="URL" />
        <textarea class="description" ref="description" placeholder="Description">
          {item.description}
        </textarea>
      </div>
      <div class="Controls">
        <Control onClick={this.onSubmit} icon="ok" label="Submit" />
        <Control onClick={this.onCancel} icon="remove" label="Cancel" />
      </div>
     </div>`

UserView = React.createClass
  render: ->
    `<div class="User"></div>`

Modal = React.createClass
  $getDOMNode: ->
    $ this.getDOMNode()

  componentDidMount: ->
    $node = this.$getDOMNode()
    $node.modal(backdrop: 'static', show: not this.props.hide)
    $node.on 'shown.bs.modal',  this.props.onShow if this.props.onShow?
    $node.on 'hidden.bs.modal', this.props.onHide if this.props.onHide?

  componentWillUnmount: ->
    this.hide()

  hide: ->
    this.$getDOMNode().modal 'hide'

  show: ->
    this.$getDOMNode().modal 'show'

  onBodyClick: (e) ->
    e.stopPropagation() unless e.target == this.refs.modalBody.getDOMNode()

  render: ->
    `<div onClick={this.props.onClick} class="modal fade">
      <div class="modal-dialog">
        <div class="modal-body" ref="modalBody" onClick={this.onBodyClick}>
          {this.props.children}
        </div>
      </div>
     </div>`

LoginDialog = React.createClass
  render: ->
    `<div class="LoginDialog">
      <div onClick={Wall.hideModal} class="Controls">
        <Control href="/auth/facebook" label="Sign in with Facebook" icon="facebook" />
        <Control href="/auth/twitter" label="Sign in with Twitter" icon="twitter" />
      </div>
     </div>`

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
    'click a': (e) ->
      href = e.currentTarget.attributes?.href?.value
      if href? and not /https?:/.exec href
        e.preventDefault()
        this.router.navigate href, trigger: true

  getInitialState: ->
    user = try
      JSON.parse window.localStorage.getItem('wall.user')
    catch e
      null
    {user}

  componentDidMount: ->
    this.listenTo this.router, 'route:items', =>
      model = new Items()
      model.fetch().then => this.show new ItemsScreen {model}
    this.listenTo this.router, 'route:item', (id) =>
      model = new Item {id}
      model.fetch().then => this.show new ItemScreen {model}
    this.listenTo this.router, 'route:auth', (provider) =>
      window.open(window.location.pathname)
      Backbone.history.history.back()

  show: (screen, options = {}) ->
    this.setState {screen}
    screenURL = screen.url()
    this.router.navigate screenURL, {trigger: options.trigger} if screenURL?

  renderControls: ->
    controls = if this.getUser()?
      [Control(
        class: 'submit', icon: 'pencil', label: 'Submit',
        onClick: => this.showModal WriteScreen()),
       Control(
        class: 'logout', icon: 'signout',
        href: '/auth/logout', label: 'Sign out')]
    else
      [Control(
        class: 'login', icon: 'signin', label: 'Sign in',
        onClick: => this.showModal LoginDialog())]
    `<div class="Controls">{controls}</div>`

  render: ->
    screen = this.state?.screen
    `<div class="App">
      <header>
        <h1 class="title"><a href="/">{this.props.title}</a></h1>
        {this.renderControls()}
      </header>
      <div class="screen">{screen}</div>
      {this.renderModal()}
     </div>`

window.onload = ->
  Wall = window.Wall = App(title: "wall")
  React.renderComponent Wall, document.body
  Backbone.history.start(pushState: true)
