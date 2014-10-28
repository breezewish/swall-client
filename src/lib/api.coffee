pkginfo = require('pkginfo')(module, 'name', 'version')
request = require('request')

class RequestFactory
    constructor: (host) ->
        @host = host
        @r = request.defaults
            gzip: true
            json: true
            strictSSL: false
            encoding: null
            headers:
                'User-Agent': module.exports.name + '/' + module.exports.version

    get: (url, callback) ->
        @r.get @host + url, @_parse(callback)

    post: (url, options, callback) ->
        @r.post @host + url, options, @_parse(callback)

    _parse: (callback) ->
        (err, response, body) ->
            return callback err if err
            return callback new Error('Invalid JSON') if typeof body isnt 'object'
            return callback new Error(body.msg) if body.error
            callback null, body

module.exports = (host) -> new RequestFactory(host)