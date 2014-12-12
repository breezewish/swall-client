path      = require 'path'
mkdirp    = require 'mkdirp'
open      = require 'open'
findit    = require 'findit'
async     = require 'async'
hash      = require 'checksum'
fs        = require 'fs'
thumbnail = require './thumbnail.js'

Assets =
    getDirectory: (id) ->
        path.join PUBLIC_DIRECTORY, "assets_#{id}"

    getThumbnailDirectory: (id) ->
        path.join Assets.getDirectory(id), "thumbnail"

    getRelativeURI: (file) ->
        s = path
            .relative PUBLIC_DIRECTORY, file
            .split path.sep
            .map encodeURIComponent
            .join '/'
        "/#{s}"

    createDirectory: (id, callback) ->
        mkdirp Assets.getThumbnailDirectory(id), callback

    openDirectory: (id) ->
        open Assets.getDirectory(id)

    get: (id, hash, callback) ->
        DB.all 'SELECT description, URI, thumbnailURI, type, hash FROM ASSET WHERE hash = $hash AND SCREENID = $sid LIMIT 1',
            $sid: id
            $hash: hash
        , (err, data) ->
            return callback && callback err if err
            return callback && callback() if data.length is 0
            callback null, data[0]

    queryAll: (id, callback) ->
        DB.all 'SELECT description, URI, thumbnailURI, type, hash FROM ASSET WHERE SCREENID = $sid AND valid = 1 ORDER BY description ASC',
            $sid: id
        , callback

    # deprecated
    # 
    # updateDescription: (id, hash, description, callback) ->
    #     DB.run 'UPDATE ASSET SET description = $desc WHERE hash = $hash AND SCREENID = $sid',
    #         $desc: description
    #         $hash: hash
    #         $sid: id
    #     , (err) ->
    #         return callback && callback err if err
    #         Assets.queryAll id, callback

    scan: (id, callback) ->
        f = []
        async.series [
            (callback) ->
                # Get all files
                Assets._scanFile id, (files) ->
                    f = files
                    callback()

            (callback) ->
                # Reset flags
                DB.run 'UPDATE ASSET SET valid = 0 WHERE SCREENID = $sid',
                    $sid: id
                , callback

            (callback) ->
                async.eachSeries f, (fObj, callback) ->
                    assetsHash = null
                    thumbnailPath = null
                    async.series [
                        (callback) ->
                            # calculate hash
                            hash.file fObj.path, (err, sum) ->
                                assetsHash = sum
                                thumbnailPath = path.join(Assets.getThumbnailDirectory(id), "#{assetsHash}.thumbnail.jpg") if fObj.type isnt 'html'
                                callback()

                        (callback) ->
                            # create thumbnail
                            return callback() if fs.existsSync(thumbnailPath)
                            return callback() if fObj.type is 'html'
                            thumbnail fObj.path, thumbnailPath, fObj.type, callback

                        (callback) ->
                            thumbnail_final = ''
                            thumbnail_final = Assets.getRelativeURI thumbnailPath if fObj.type isnt 'html'
                            # update database
                            DB.run 'INSERT OR REPLACE INTO ASSET
                                (AID, SCREENID, type, description, hash, URI, thumbnailURI, valid) VALUES
                                ((SELECT AID FROM ASSET WHERE URI = $URI AND SCREENID = $sid), 
                                 $sid,
                                 $type,
                                 $name,
                                 $hash,
                                 $URI,
                                 $thumbnailURI,
                                 1
                                 )',
                                $sid: id
                                $name: path.basename(fObj.path)
                                $type: fObj.type
                                $hash: assetsHash
                                $URI: fObj.relative
                                $thumbnailURI: thumbnail_final
                            , callback
                    ], callback
                , callback
        ], (err) ->
            return callback && callback err if err
            Assets.queryAll id, callback

    _scanFile: (id, callback) ->
        files = []
        directory = Assets.getDirectory(id)

        f = fs.readdirSync directory
        for file in f
            fp = path.join(directory, file)
            stat = fs.statSync fp
            continue if stat.isDirectory()
            continue if fp.toLowerCase().indexOf('.thumbnail.') > -1
            # get assets type
            ext = path.extname(fp).toLowerCase()
            if ext in CONFIG.AssetsFilter.Video
                type = 'video'
            else if ext in CONFIG.AssetsFilter.Image
                type = 'image'
            else if ext in CONFIG.AssetsFilter.Webpage
                type = 'html'
            else
                continue
            files.push
                path: fp
                type: type
                relative: Assets.getRelativeURI fp

        callback && callback files

module.exports = Assets;