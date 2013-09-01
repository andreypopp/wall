React             = require 'react-tools/build/modules/React'
Timestamp         = require 'react-time'
url               = require 'url'
{Item}            = require '../models'

username = (user) ->
  user.split('@')[0]

module.exports = React.createClass
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
    `<div class={cls} tabIndex="1"
        onTouchStart={this.onFocus}
        onFocus={this.onFocus}
        onKeyDown={this.onKeyDown}>
      <div class="meta">
        {this.renderIcon()}
        {item.title && <h4 class="title"><a tabIndex="-1" href={mainLink}>
          {item.title}
        </a></h4>}
        {item.post && this.props.full && <div class="post">{item.post}</div>}
        {item.uri && <a class="uri" tabIndex="-1" href={item.uri}>
          {item.uri && url.parse(item.uri).hostname}
        </a>}
        <Timestamp class="created" relative value={item.created} />
        <div class="creator">by {username(item.creator)}</div>
      </div>
      {this.props.children}
     </div>`

