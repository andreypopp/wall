###

  Database access layer

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

kew         = require 'kew'
pg          = require 'pg'
sql         = require 'sql'
{extend}    = require 'underscore'

withDB = (database) ->
  (req, res, next) ->
    pg.connect database, (err, db, done) ->
      res.on 'finish', -> query(db, "ROLLBACK").fin(done)
      query(db, "BEGIN").then ->
        return next err if err
        req.db = db
        next()

query = (db, text, values...) ->
  {text, values}  = text.toQuery() if text.toQuery?
  promise = kew.defer()
  db.query text, values, (err, result) ->
    if err then promise.reject(err) else promise.resolve(result)
  promise

queryRows = (args...) ->
  query(args...).then (res) -> res.rows

queryRow = (args...) ->
  query(args...).then (res) -> res.rows[0]

items = sql.define
  name: 'items'
  columns: [
    'id', 'title', 'uri', 'post',
    'created', 'updated', 'creator',
    'parent', 'child_count']

module.exports = extend pg, {items, withDB, query, queryRows, queryRow}
