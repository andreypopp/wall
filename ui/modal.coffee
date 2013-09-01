React     = require 'react-tools/build/modules/React'
{isArray} = require 'underscore'

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

module.exports = HasModal
