DOMEvents               = require 'react-dom-events'
React                   = require 'react-tools/build/modules/React'
FocusController         = require './focus_controller'
Control                 = require './control'
ItemView                = require './item_view'
HasComments             = require './comments'
{Item}                  = require '../models'
{UserAware, HasScreen}  = require './utils'

module.exports = React.createClass
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
