events = require 'events'
io     = require 'socket.io-client'
async  = require 'async'
fs     = require 'fs'
url    = require 'url'

Assets = require './assets.js'

class ScreenManager extends events.EventEmitter
    constructor: (host) ->
        @host = host
        @_reset()
        @_connectLast()

        # bind initial events
        for kind in ['connecting', 'connect', 'disconnect', 'reconnecting', 'reconnect_failed']
            @on kind, =>
                SERVER.io.to('controller').emit 'statusChange',
                    type: 'clientToServer'
                    status: @status

    _reset: =>
        @conencted = false
        @status = 'Disconnected'
        @socket = null
        @data = {}

        @preference =
            URI: CONFIG.Client.Service
            danmaku:
                visible:  true
                duration: 10
                maxline:  7
            asset: {}

    _connectLast: (callback) =>
        DB.all 'SELECT * FROM META WHERE key = $key LIMIT 1',
            $key: 'LAST_SCREENID'
        , (err, data) =>
            if data? and data.length > 0
                @connect data[0].value, callback
            else
                callback && callback()

    _saveLast: (callback) =>
        DB.run 'INSERT OR REPLACE INTO META (key, value) VALUES ($key, $value)',
            $key: 'LAST_SCREENID'
            $value: @data.id
        , callback

    # Connect to remote
    connect: (id, callback) =>
        if @connected
            @disconnect => @_connect(id, callback)
        else
            @_connect(id, callback)

    _connect: (id, callback) =>
        async.series [
            (callback) =>
                # query data
                API.get "/#{id}/info", (err, data) =>
                    return callback err if err
                    @data = data
                    info 'API connected to screen #%s', id
                    callback()

            (callback) =>
                # update preference URI
                @preference.URI = "#{CONFIG.Client.Service}/#{@data.id}"

                # create (if not exists) assets directory
                Assets.createDirectory @data.id, callback

            (callback) =>
                # update database
                DB.run 'INSERT OR REPLACE INTO INFO (SID, data) VALUES ($sid, $data)',
                    $sid: @data.id
                    $data: JSON.stringify(@data)
                , callback

            (callback) =>
                # query preference
                DB.all 'SELECT * FROM PREFERENCE WHERE SID = $sid LIMIT 1',
                    $sid: @data.id
                , (err, data) =>
                    @preference = JSON.parse(data[0].DATA) if data? and data.length > 0
                    callback()

            (callback) =>
                @_saveLast callback

            (callback) =>
                # connect to realtime server
                socket = @socket = io @host

                status = 'Connecting'
                @emit 'connecting'

                socket.on 'connect', =>
                    info 'Channel #%s: Connected', id
                    @status = 'Connected'
                    @emit 'connect'
                    socket.emit '/subscribe', id: id

                socket.on 'comment', (data) =>
                    @comment data
                    @emit 'comment', data

                socket.on 'disconnect', =>
                    info 'Channel #%s: Disconnected', id
                    @status = 'Disconnected'
                    @emit 'disconnect'

                socket.on 'reconnect', (attempt) =>
                    info 'Channel #%s: Reconnected %d', id, attempt
                    @emit 'reconnect', attempt

                socket.on 'reconnect_attempt', =>
                    @emit 'reconnect_attempt'

                socket.on 'reconnecting', (attempt) =>
                    info 'Channel #%s: Reconnecting %d', id, attempt
                    @status = 'Reconnecting'
                    @emit 'reconnecting', attempt

                socket.on 'reconnect_error', (err) =>
                    @emit 'reconnect_error', err

                socket.on 'reconnect_failed', =>
                    info 'Channel #%s: Reconnect failed', id
                    @status = 'Reconnect failed'
                    @emit 'reconnect_failed'

                @connected = true
                callback()
                
        ], (err) =>
            error err if err
            callback && callback null, @data

    # Disconnect from remote
    disconnect: (callback) =>
        @socket.disconnect() if @socket # disconnect socket
        @_reset()
        callback && callback()

    # Get Screen -> Server Status
    getStatus: (callback) =>
        callback && callback null,
            connected: @connected
            status:    @status

    # Reveal assets directory
    revealAssets: (callback) =>
        throw new Error('Please connect to a screen') if not @connected
        Assets.openDirectory @data.id
        callback && callback()

    # Scan assets directory and add missing assets
    scanAssets: (callback) =>
        throw new Error('Please connect to a screen') if not @connected
        Assets.scan @data.id, callback

    # Update the description of an asset and return all assets
    updateAssetDesc: (hash, description, callback) =>
        throw new Error('Please connect to a screen') if not @connected
        Assets.updateDescription @data.id, hash, description, callback

    # Update walls' background
    switchToAsset: (hash, callback) =>
        Assets.get @data.id, hash, (err, asset) =>
            return callback && callback err if err
            return callback && callback new Error('Asset not found') if not asset
            SERVER.io.to('wall').emit 'switchTo', asset
            @preference.asset = asset
            @_updatePreference -> callback && callback()

    # Get wall's current background
    getCurrentAsset: (callback) =>
        callback && callback null, asset: @preference.asset

    # Send comment to the wall
    comment: (data, callback) =>
        SERVER.io.to('wall').emit 'comment', data
        callback && callback()

    # Set danmaku's visibility
    setDanmakuVisibility: (visibility, callback) =>
        SERVER.io.to('wall').emit 'setVisibility', visibility
        @preference.danmaku.visible = visibility
        @_updatePreference -> callback && callback()

    # Update danmaku's duration & maxline settings
    updateDanmakuSettings: (duration, maxline, callback) =>
        SERVER.io.to('wall').emit 'updateSettings',
            duration: duration
            maxline: maxline
        @preference.danmaku.duration = duration
        @preference.danmaku.maxline = maxline
        @_updatePreference -> callback && callback()

    # Update preference into database
    _updatePreference: (callback) =>
        DB.run 'INSERT OR REPLACE INTO PREFERENCE (SID, data) VALUES ($sid, $data)',
            $sid: @data.id
            $data: JSON.stringify(@preference)
        , callback

    # Get wall's preference data
    getWallPreference: (callback) =>
        callback && callback null, @preference

    # Get a short URI
    getShortcutURI: =>
        part = url.parse @preference.URI
        "#{part.host}#{part.path}"

module.exports = (host) -> new ScreenManager(host)
module.exports.ScreenManager = ScreenManager