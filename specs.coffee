{ok, equal: eq} = require 'assert'
{all}           = require 'kew'
uuid            = require 'node-uuid'
express         = require 'express'
request         = require 'supertest'
{api}           = require './index'
db              = require './db'

TEST_DATABASE = 'postgres://localhost/walltest'
TEST_USER = {id: 1, username: 'user'}
TEST_ITEM_ID = uuid.v4()
TEST_ITEM_ID_2 = uuid.v4()
TEST_ITEMS = [
  {id: TEST_ITEM_ID, creator: TEST_USER.id, title: 'title', uri: 'http://example.com'},
  {creator: TEST_USER.id, post: 'post', uri: 'http://example.com'},
  {id: TEST_ITEM_ID_2, creator: TEST_USER.id, post: 'post', uri: 'http://example.com', parent: TEST_ITEM_ID},
  {creator: TEST_USER.id, post: 'post', uri: 'http://example.com', parent: TEST_ITEM_ID_2},
]


before (done) ->
  db.connect TEST_DATABASE, (err, conn) ->
    return done(err) if err
    db.query(conn, "TRUNCATE items").then ->
      promises = for item in TEST_ITEMS
        q = db.items.insert(item)
        db.query(conn, q)
      all(promises).fin(done)

describe 'api', ->

  makeApp = (options = {}) ->
    app = express()
    unless options.anonymous
      app.use (req, res, next) ->
        req.user = TEST_USER
        next()
    app.use api(database: TEST_DATABASE)
    app

  describe 'creating a new item', ->

    assertItemCreated = (item) ->
      ok item
      ok item.id
      ok item.created
      ok item.updated
      ok item.creator

    create = (data, assertBody) ->
      request(makeApp())
        .post('/items')
        .send(data)
        .expect(200)

    it 'creates a new item', (done) ->
      create().end (err, res) ->
        assertItemCreated res.body
        done(err)

    it 'creates a new item with a title', (done) ->
      create(title: 'Title').end (err, res) ->
        assertItemCreated res.body
        eq res.body.title, 'Title'
        done(err)

    it 'creates a new item with a URI', (done) ->
      create(uri: 'http://example.com').end (err, res) ->
        assertItemCreated res.body
        eq res.body.uri, 'http://example.com'
        done(err)

    it 'creates a new item with a post', (done) ->
      create(post: 'some text').end (err, res) ->
        assertItemCreated res.body
        eq res.body.post, 'some text'
        done(err)

  describe 'getting a list of items', ->

    it 'fetches a list of items', (done) ->
      request(makeApp())
        .get('/items')
        .expect(200)
        .end (err, res) ->
          done(err)
          ok res.body
          ok res.body.items
          eq res.body.items.length, 2

  describe 'getting a single item', ->

    it 'fetches a single item', (done) ->
      request(makeApp())
        .get("/items/#{TEST_ITEM_ID}")
        .expect(200)
        .end (err, res) ->
          ok res.body
          eq res.body.id, TEST_ITEM_ID
          ok res.body.comments
          eq res.body.comments.length, 1
          eq res.body.comments[0].parent, res.body.id
          ok res.body.comments[0].comments
          eq res.body.comments[0].comments.length, 1
          eq res.body.comments[0].comments[0].parent, res.body.comments[0].id
          done(err)
