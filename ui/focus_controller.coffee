{min, max} = Math

module.exports =

  componentDidMount: ->
    focusItems = this.focusItems

    getFocusables = => $(focusItems, this.getDOMNode())

    this.delegateDOMEvents "focus:next #{focusItems}", (e) ->
      $nodes = getFocusables()
      idx = $nodes.index e.target
      idx = min(idx + 1, $nodes.length - 1)
      $($nodes.get(idx)).focus()

    this.delegateDOMEvents "focus:prev #{focusItems}", (e) ->
      $nodes = getFocusables()
      idx = $nodes.index e.target
      idx = max(idx - 1, 0)
      $($nodes.get(idx)).focus()

    this.delegateDOMEvents "focus:active #{focusItems}", (e) ->
      $nodes = getFocusables()
      $nodes.not(e.target).attr('tabindex', -1).blur()
      $(e.target).attr('tabindex', 0)
