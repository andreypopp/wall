{max, min}                        = Math
express                           = require 'express'
{all, resolve}                    = require 'kew'
{authenticated}                   = require './auth'
{Item}                            = require './models'
db                                = require './db'

{queryScalar, queryRow, queryRows} = db
{items_ordered, items}             = db

model = (modelClass) ->
  (req, res, next) ->
    try
      m = new modelClass(req.body, parse: true)
    catch e
      return next(e)
    unless m.isValid()
      res.send 400, m.validationError
    else
      req.model = m
      next()

promise = (func) ->
  (req, res, next) ->
    func(req, res, next)
      .then (result) ->
        if result == undefined then res.send 404 else res.send result
      .fail(next)
      .end()

module.exports = (options = {}) ->

  readingDB = (handler) -> (req, res, next) ->
    db.connect(options.database)
      .then (conn) ->
        req.conn = conn
        handler(req, res, next)
      .fin ->
        req.conn.release()

  writingDB = (handler) ->
    readingDB (req, res, next) ->
      db.begin(req.conn).then ->
        handler(req, res, next)
          .then (result) ->
            db.commit(req.conn).then -> result
          .fail (err) ->
            db.rollback(req.conn).then -> throw err

  orderById = (conn, id) ->
    q = items_ordered
      .select(items_ordered.order)
      .where(items_ordered.id.equal(id))
    queryScalar(conn, q)

  idByOrder = (conn, order) ->
    q = items_ordered
      .select(items_ordered.id)
      .where(items_ordered.order.equal(order))
    queryScalar(conn, q)

  app = express()
  app.use express.bodyParser()

  app.get '/items', promise readingDB (req, res) ->
    limit = min(req.query.limit or 2, 100)
    after = req.query.after or undefined

    order = if after? then orderById(req.conn, after) else resolve(1)

    prevId = order.then (order) ->
      idByOrder req.conn, max(1, order - limit)

    all([order, prevId]).then ([order, prevId]) ->
      q = items_ordered.select()
        .where(items_ordered.parent.isNull())
        .order(items_ordered.created.desc)
        .limit(limit + 1)

      if order != 1
        q = q.where(items_ordered.order.gte(order))

      queryRows(req.conn, q).then (items) ->
        nextId = items[limit]?.id if items.length == limit + 1
        prevId = null if items[0]?.id == prevId

        items = items.slice(0, limit)
        {items, nextId, prevId, limit: req.query.limit, after: req.query.after}

  app.post '/items', authenticated, model(Item), promise writingDB (req, res) ->
    data = req.body or {}
    data.creator = req.user.id
    q = items.insert(data).returning(items.star())
    queryRow(req.conn, q).then (item) ->
      item.comments = []
      item

  app.get '/items/:id', promise readingDB (req, res) ->
    q = """
      with recursive comments as (
        select items.* from items where id = $1
          union
        select items.* from items join comments on comments.id = items.parent)
      select * from comments
    """
    queryRows(req.conn, q, req.params.id).then (items) ->
      rootId = items[0].id
      mapping = {}
      for item in items
        mapping[item.id] = item
        item.comments = []
        parent = mapping[item.parent]
        parent.comments.push(item) if parent
      mapping[rootId]

  app
