React             = require 'react-tools/build/modules/React'
DOMEvents         = require 'react-dom-events'
ItemView          = require './item_view'
Pagination        = require './pagination'
FocusController   = require './focus_controller'
{HasScreen}       = require './utils'
{Items}           = require '../models'

module.exports = React.createClass
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
    `<div class="ItemsScreen">
      <div class="items">{children}</div>
      <Pagination model={this.props.model} />
     </div>`
