React = require 'react-tools/build/modules/React'

module.exports = React.createClass
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
    tabIndex = this.props.tabIndex or 0
    label = `<span class="label">{this.props.label}</span>` if this.props.label
    icon = `<i class={iconClass}></i>` if this.props.icon
    `<a onClick={this.onClick} onKeyDown={this.onKeyDown}
        tabIndex={tabIndex} class={selfClass} href={this.props.href}>
          {this.props.iconRight ? [label, icon] : [icon, label]}
     </a>`
