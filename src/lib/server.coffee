express = require 'express'
path = require 'path'
bodyParser = require 'body-parser'
stylus = require 'stylus'

app = express()
server = require('http').createServer(app)
io = require('socket.io')(server)

io.sockets.on 'connection', (socket) ->
    socket.on 'identify', (data) ->
        socket.join data

app.io = io

app.set 'views', VIEW_DIRECTORY
app.set 'view engine', 'ejs'

app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)
app.use stylus.middleware
    src: PUBLIC_DIRECTORY
    compile: (str, path) ->
        stylus(str)
        .set 'filename', path
        .use require('autoprefixer-stylus')()
app.use express.static(PUBLIC_DIRECTORY)

routes = require '../routes/index'

app.use '/', routes
app.use '/control', routes.control
app.use '/wall', routes.wall

# catch 404 and forward to error handler
app.use (req, res, next) ->
    err = new Error('Not Found')
    err.status = 404
    next(err)

# error handlers
app.use (err, req, res, next) ->
    res.status err.status || 500
    res.json
        error: true
        msg: err.message

module.exports = (port) ->
    server.listen port, ->
        info 'Listening at :%s', port
    app