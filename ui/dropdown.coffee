React   = require 'react-tools/build/modules/React'
Control = require './control'

module.exports = React.createClass

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
