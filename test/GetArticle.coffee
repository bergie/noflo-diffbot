readenv = require "../components/GetArticle"
socket = require('noflo').internalSocket

setupComponent = ->
  c = readenv.getComponent()
  ins = socket.createSocket()
  token = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.token.attach token
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, ins, token, out, err]

exports['test reading a URL without Token'] = (test) ->
  test.expect 3
  [c, ins, token, out, err] = setupComponent()
  err.once 'data', (data) ->
    test.ok data
    test.equal data.errorCode, 401
    test.ok data.error
    test.done()

  ins.send 'http://bergie.iki.fi/blog/jolla-sailfish/'

exports['test reading a URL'] = (test) ->
  unless process.env.DIFFBOT_TOKEN
    test.fail null, null, 'No DIFFBOT_TOKEN env variable set'
    test.done()
    return

  [c, ins, token, out, err] = setupComponent()

  out.once 'data', (data) ->
    test.ok data, "We need to get an article object"
    test.ok data.html, "Article needs to contain text"

    test.ok data.title, "Article needs to contain a title"
    test.ok data.title.indexOf('Sailfish OS') isnt -1, "Title must look correct"

    test.ok data.type, "Article must have type"
    test.equal data.type, 'article', "Article type must be 'article'"

    test.done()

  token.send process.env.DIFFBOT_TOKEN
  ins.send 'http://bergie.iki.fi/blog/jolla-sailfish/'

exports['test reading two URLs'] = (test) ->
  unless process.env.DIFFBOT_TOKEN
    test.fail null, null, 'No DIFFBOT_TOKEN env variable set'
    test.done()
    return

  [c, ins, token, out, err] = setupComponent()

  expects = [
    title: 'Sailfish OS'
    url: 'http://bergie.iki.fi/blog/jolla-sailfish/'
  ,
    title: 'Create.js in 2013'
    url: 'http://bergie.iki.fi/blog/createjs-in-2013/'
  ]

  fetched = 0
  out.on 'data', (data) ->
    fetched++
    expected = {}
    for expection in expects
      expected = expection if expection.url is data.url
    test.ok expected.title

    test.ok data, "We need to get an article object"
    test.ok data.html, "Article needs to contain text"
    test.ok data.title, "Article needs to contain a title"
    test.ok data.title.indexOf(expected.title) isnt -1, "Title must look correct"
    test.ok data.type, "Article must have type"
    test.equal data.type, 'article', "Article type must be 'article'"

    test.done() if fetched is 2

  token.send process.env.DIFFBOT_TOKEN
  ins.send 'http://bergie.iki.fi/blog/jolla-sailfish/'
  ins.send 'http://bergie.iki.fi/blog/createjs-in-2013/'
