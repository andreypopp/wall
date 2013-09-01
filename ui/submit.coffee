React                             = require 'react-tools/build/modules/React'
Textarea                          = require 'react-textarea-autosize'
{HasScreen, AppEvents, animate}   = require './utils'
Control                           = require './control'
ItemScreen                        = require './item_screen'
{Item}                            = require '../models'

module.exports = React.createClass

  mixins: [HasScreen, AppEvents]

  getInitialState: ->
    {model: new Item}

  focus: ->
    this.refs.uri.getDOMNode().focus()

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
    `<div class="SubmitDialog" onKeyDown={this.onKeyDown}>
      <div class="form">
        <input 
          type="text" class="uri" ref="uri" value={item.uri} placeholder="URL" />
        <input
          type="text" class="title" ref="title" value={item.title} placeholder="Title" />
        <Textarea
          autosize class="post" ref="post" placeholder="Description">
          {item.post}
        </Textarea>
      </div>
      <div class="Controls">
        <Control onClick={this.onSubmit} icon="ok" label="Submit" />
        <Control onClick={this.cancel} icon="remove" label="Cancel" />
      </div>
     </div>`
