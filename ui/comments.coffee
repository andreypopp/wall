React                           = require 'react-tools/build/modules/React'
Textarea                        = require 'react-textarea-autosize'
Control                         = require './control'
ItemView                        = require './item_view'
{UserAware, HasScreen, animate} = require './utils'
{Item}                          = require '../models'

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

Comments = React.createClass
  render: ->
    comments = this.props.comments.map (comment) =>
      CommentView(model: comment)
    `<div class="Comments">{comments}</div>`

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
    this.refs.post.getDOMNode().focus()

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

module.exports = HasComments
