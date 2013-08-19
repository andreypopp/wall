{Collection}                    = require 'backbone'
{Record, invariant, attribute}  = require 'backbone.record'

class Item extends Record
  @define
    title: attribute.String.optional()
    uri: attribute.String.optional()
    post: attribute.String.optional()
    created: attribute.optionalWhenNew()
    updated: attribute.optionalWhenNew()
    creator: attribute.String.optionalWhenNew()
    parent: attribute.String.optionalWhenNew()
    child_count: attribute.Number.optionalWhenNew()
    comments: attribute.optionalWhenNew()

  @invariant invariant.requireOneOf('uri', 'post')
  @invariant invariant.requireOneOf('title', 'parent')

  url: ->
    if this.id? then "/api/items/#{this.id}" else "/api/items"

  screenURL: ->
    if this.id? then "/items/#{this.id}"

class ItemCollection extends Collection
  model: Item

Item::schema.comments = attribute.ofType(ItemCollection).optionalWhenNew()

class Items extends Record
  @define
    items: attribute.ofType(ItemCollection)

  url: ->
    '/api/items'

  screenURL: ->
    '/'

module.exports = {Item, Items}
