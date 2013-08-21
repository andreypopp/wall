###

  Thin database access layer based on promises.

  Under MIT license, see LICENSE file for details
  Andrey Popp (c) 2013

###

{defer}     = require 'kew'
pg          = require 'pg'
sql         = require 'sql'
{extend}    = require 'underscore'

connect = (uri) ->
  promise = defer()
  pg.connect uri, (err, conn, done) ->
    if err
      promise.reject(err)
    else
      conn.release = done
      promise.resolve(conn)
  promise

query = (db, text, values...) ->
  {text, values}  = text.toQuery() if text.toQuery?
  promise = defer()
  db.query text, values, (err, result) ->
    if err then promise.reject(err) else promise.resolve(result)
  promise

queryRows = (args...) ->
  query(args...).then (res) -> res.rows

queryRow = (args...) ->
  query(args...).then (res) -> res.rows[0]

queryScalar = (args...) ->
  query(args...).then (res) ->
    row = res.rows[0]
    columnName = Object.keys(row)[0]
    row[columnName]

begin = (db) ->
  query(db, "BEGIN")

commit = (db) ->
  query(db, "COMMIT")

rollback = (db) ->
  query(db, "ROLLBACK")

items = sql.define
  name: 'items'
  columns: [
    'id', 'title', 'uri', 'post',
    'created', 'updated', 'creator',
    'parent', 'child_count']

items_ordered = sql.define
  name: 'items_ordered'
  columns: [
    'id', 'title', 'uri', 'post',
    'created', 'updated', 'creator',
    'parent', 'child_count', 'order']

module.exports = extend {}, pg, {
  items, items_ordered,
  connect, begin, commit, rollback,
  query, queryRows, queryRow, queryScalar}
