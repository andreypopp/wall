React   = require 'react-tools/build/modules/React'
Control = require './control'

module.exports = React.createClass
  render: ->
    {prevId, nextId} = this.props.model
    prev = if prevId
      Control
        class: 'prev'
        label: 'Newer'
        icon: 'arrow-left'
        href: "/?#{qs.stringify(after: prevId)}"
    next = if nextId
      Control
        class: 'next'
        label: 'Older'
        iconRight: true
        icon: 'arrow-right'
        href: "/?#{qs.stringify(after: nextId)}"
    `<div class="Pagination Controls">{prev}{next}</div>`
