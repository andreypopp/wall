###*

  UI entry point

  @jsx React.DOM

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

url                           = require 'url'
{extend, result, isArray}     = require 'underscore'
Backbone                      = require 'backbone'
Record                        = require 'backbone.record'
Backbone.$                    = require 'jqueryify'
React                         = require 'react-tools/build/modules/react'
Timestamp                     = require 'react-time'
DOMEvents                     = require 'react-dom-events'
Textarea                      = require 'react-textarea-autosize'
{Item, Items}                 = require '../models'
_BootstrapModal               = require './bootstrap-modal'

username = (user) ->
  user.split('@')[0]

animate = (node, animation) ->
  $node = $ node
  $node.one 'oanimationend animationend webkitAnimationEnd', ->
    $node.removeClass animation
  $node.addClass animation

FocusController =

  componentDidMount: ->
    focusItems = this.focusItems

    getFocusables = => $(focusItems, this.getDOMNode())

    this.delegateDOMEvents "focus:next #{focusItems}", (e) ->
      $nodes = getFocusables()
      idx = $nodes.index e.target
      idx = Math.min(idx + 1, $nodes.length - 1)
      $($nodes.get(idx)).focus()

    this.delegateDOMEvents "focus:prev #{focusItems}", (e) ->
      $nodes = getFocusables()
      idx = $nodes.index e.target
      idx = Math.max(idx - 1, 0)
      $($nodes.get(idx)).focus()

    this.delegateDOMEvents "focus:active #{focusItems}", (e) ->
      $nodes = getFocusables()
      $nodes.not(e.target).attr('tabindex', -1).blur()
      $(e.target).attr('tabindex', 0)

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
    this.setState(user: this.getUser()) if e.key == this.USER_KEY

  componentDidMount: ->
    Backbone.$(window).on "storage", this._handleStorageEvent

  componentWillUnmount: ->
    Backbone.$(window).off "storage", this._handleStorageEvent

HasModal =
  renderModal: ->
    if this.state?.modal
      `<Modal ref="modal"
        onShow={this.onModalShow}
        onHide={this.onModalHide}
        onClick={this.hideModal}>{this.state.modal}</Modal>`

  onModalShow: ->
    this.refs.modal.focus()

  onModalHide: ->
    this.setState(modal: undefined)

  showModal: (screen) ->
    this.setState(modal: screen)

  hideModal: ->
    this.refs.modal.hide()

HasScreen =
  url: -> result this.props.model, 'screenURL'

HasComments =
  onAddComment: ->
    this.setState(commentEditorShown: true)

  onCommentCancel: ->
    this.setState(commentEditorShown: false)

  onCommentSubmit: (value) ->
    comment = new Item(post: value, parent: this.props.model.id)
    if comment.isValid()
      this.props.model.comments.add(comment)
      comment.save().then =>
        this.setState(commentEditorShown: false)
    else
      animate this.refs.commentEditor.getDOMNode(), 'invalid'

  renderCommentEditor: ->
    if this.state?.commentEditorShown
      `<CommentEditor ref="commentEditor" autofocus
          onSubmit={this.onCommentSubmit}
          onCancel={this.onCommentCancel} />`

  renderComments: ->
    if this.props.model.comments?.length > 0
      Comments(comments: this.props.model.comments)

Control = React.createClass
  onKeyDown: (e) ->
    this.onClick() if e.keyCode == 13

  onClick: ->
    if this.props.onClick?
      this.props.onClick()
    else
      Wall.router.navigate(this.props.href, trigger: true)

  render: ->
    iconClass = "icon icon-#{this.props.icon}"
    selfClass = "Control #{this.props.class or ''}"
    label = if this.props.label
      `<span class="label">{this.props.label}</span>`
    `<a onClick={this.onClick} onKeyDown={this.onKeyDown}
        tabIndex={this.props.tabIndex || 0} class={selfClass} href={this.props.href}>
      {this.props.icon && <i class={iconClass}></i>}{label}
     </a>`

Dropdown = React.createClass

  toggle: ->
    if this.isShown() then this.hide() else this.show()

  show: ->
    this.getDOMNode().classList.add('shown')

  hide: (e) ->
    this.getDOMNode().classList.remove('shown')

  isShown: ->
    this.getDOMNode().classList.contains('shown')

  onBlur: ->
    # so click event can fire
    setTimeout(this.hide, 50)

  render: ->
    selfClass = "Dropdown #{this.props.className or ''}"
    `<div onBlur={this.onBlur} class={selfClass}>
      <Control tabIndex={this.props.tabIndex}
        onClick={this.toggle} icon={this.props.icon}
        href={this.props.href} label={this.props.label} />
      <div ref="menu" role="menu" class="menu">
        {this.props.children}
      </div>
     </div>`

ItemsScreen = React.createClass
  mixins: [HasScreen, DOMEvents, FocusController]
  propTypes:
    model: React.PropTypes.instanceOf(Items).isRequired

  focusItems: '.ItemView'

  render: ->
    children = if this.props.model.items.length > 0
      this.props.model.items.map (item) => ItemView {item}
    else
      `<div class="empty">
        <div class="off">
          <i class="icon icon-pencil"></i>
          <div class="text">found something?</div>
        </div>
       </div>`
    `<div class="ItemsScreen">{children}</div>`

ItemView = React.createClass
  propTypes:
    item: React.PropTypes.instanceOf(Item).isRequired
    externalLink: React.PropTypes.boolean
    full: React.PropTypes.boolean

  renderIcon: ->
    if this.props.item.uri
      `<i class="icon icon-globe"></i>`
    else if this.props.item.title
      `<i class="icon icon-comments"></i>`
    else
      `<i class="icon icon-comment"></i>`

  onKeyDown: (e) ->
    $node = $ this.getDOMNode()
    if e.keyCode == 13
      Wall.router.navigate(this.props.item.screenURL(), trigger: true)
    if e.keyCode == 40 or e.keyCode == 74
      $node.trigger('focus:next', $node)
    if e.keyCode == 38 or e.keyCode == 75
      $node.trigger('focus:prev', $node)

  onFocus: ->
    $node = $ this.getDOMNode()
    $node.trigger('focus:active', $node)

  render: ->
    item = this.props.item
    mainLink = if this.props.externalLink then item.uri else item.screenURL()
    cls = "ItemView #{this.props.className or ''}"
    `<div class={cls} tabIndex="1" onTouchStart={this.onFocus} onFocus={this.onFocus} onKeyDown={this.onKeyDown}>
      <div class="meta">
        {this.renderIcon()}
        {item.title && <h4 class="title"><a tabIndex="-1" href={mainLink}>{item.title}</a></h4>}
        {item.post && this.props.full && <div class="post">{item.post}</div>}
        {item.uri && <a class="uri" tabIndex="-1" href={item.uri}>{item.uri && url.parse(item.uri).hostname}</a>}
        <Timestamp class="created" relative value={item.created} />
        <div class="creator">by {username(item.creator)}</div>
      </div>
      {this.props.children}
     </div>`

CommentView = React.createClass
  mixins: [UserAware, HasComments, HasScreen]

  propTypes:
    model: React.PropTypes.instanceOf(Item).isRequired

  render: ->
    item = this.props.model
    `<div class="CommentView">
      <div class="meta">
        <ItemView full item={this.props.model} />
        <div class="Controls">
          {this.getUser() && <Control onClick={this.onAddComment} icon="reply" />}
          <Control href={this.url()} icon="link" />
        </div>
      </div>
      {this.renderCommentEditor()}
      {this.renderComments()}
     </div>`

CommentEditor = React.createClass
  focus: ->
    Backbone.$(this.refs.post.getDOMNode()).focus()

  componentDidMount: ->
    this.focus() if this.props.autofocus

  getValue: ->
    this.refs.post.getDOMNode().value.trim() or null

  onSubmit: ->
    this.props.onSubmit?(this.getValue())

  onKeyDown: (e) ->
    if e.keyCode == 27
      e.preventDefault()
      this.props.onCancel?()
    else if e.keyCode == 13 and (e.ctrlKey or e.metaKey)
      e.preventDefault()
      this.props.onSubmit?(this.getValue())

  render: ->
    `<div class="CommentEditor">
      <i class="icon icon-comment"></i>
      <Textarea onKeyDown={this.onKeyDown} autosize
        ref="post" class="post" placeholder="Your comment"></Textarea>
      <div class="Controls">
        <Control onClick={this.onSubmit} icon="ok" />
        <Control onClick={this.props.onCancel} icon="remove" />
      </div>
     </div>`

ItemScreen = React.createClass
  mixins: [UserAware, HasScreen, HasComments, DOMEvents, FocusController]
  propTypes:
    model: React.PropTypes.instanceOf(Item).isRequired
  focusItems: '.ItemView'

  renderAddCommentButton: ->
    if not this.state?.commentEditorShown and this.getUser()
      `<div class="Controls">
        <Control onClick={this.onAddComment} icon="comment" label="Discuss" />
       </div>`

  render: ->
    `<div class="ItemScreen">
      <ItemView full item={this.props.model} />
      {this.renderComments()}
      {this.renderCommentEditor()}
      {this.renderAddCommentButton()}
     </div>`

Comments = React.createClass
  render: ->
    comments = this.props.comments.map (comment) =>
      CommentView(model: comment)
    `<div class="Comments">{comments}</div>`

SubmitDialog = React.createClass
  mixins: [HasScreen, AppEvents]

  getInitialState: ->
    {model: new Item}

  focus: ->
    Backbone.$(this.refs.uri.getDOMNode()).focus()

  componentDidMount: ->
    this.listenTo this.state.model, 'invalid', =>
      animate this.getDOMNode(), 'invalid'

  submit: ->
    data =
      title: this.refs.title.getDOMNode().value or null
      uri: this.refs.uri.getDOMNode().value or null
      post: this.refs.post.getDOMNode().value or null
    this.state.model.set(data, validate: true)
    unless this.state.model.validationError
      this.state.model.save(data).then =>
        Wall.show(new ItemScreen(model: this.state.model), trigger: true)
        Wall.hideModal()

  cancel: ->
    Wall.hideModal()

  onSubmit: (e) ->
    e?.preventDefault()
    this.submit()

  onKeyDown: (e) ->
    if e.keyCode == 13 and (e.ctrlKey or e.metaKey)
      e.preventDefault()
      this.submit()

  render: ->
    item = this.state.model
    `<div class="SubmitDialog">
      <div class="form">
        <input onKeyDown={this.onKeyDown}
          type="text" class="uri" ref="uri" value={item.uri} placeholder="URL" />
        <input onKeyDown={this.onKeyDown}
          type="text" class="title" ref="title" value={item.title} placeholder="Title" />
        <Textarea onKeyDown={this.onKeyDown}
          autosize class="post" ref="post" placeholder="Description">
          {item.post}
        </Textarea>
      </div>
      <div class="Controls">
        <Control onClick={this.onSubmit} icon="ok" label="Submit" />
        <Control onClick={this.cancel} icon="remove" label="Cancel" />
      </div>
     </div>`

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

  focus: ->
    children = this.props.children
    children = [children] unless isArray children
    for child in children when child.focus?
      child.focus()

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
  Wall = window.Wall = App(title: "wall")
  Wall.settings = __data
  React.renderComponent Wall, document.body
  Backbone.history.start(pushState: true)
