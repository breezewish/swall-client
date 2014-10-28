path    = require 'path'
easyimg = require 'easyimage'
ffmpeg  = require 'fluent-ffmpeg'

createVideoThumbnail = (src, dst, callback) ->
    ffmpeg src
        .on 'end', callback
        .screenshots
            timemarks:  ['38%']
            folder:     path.dirname(dst)
            filename:   path.basename(dst)
            size:       "#{CONFIG.Thumbnail.Size.Width}x?"

createImageThumbnail = (src, dst, callback) ->
    easyimg.rescrop
        src: src
        dst: dst
        width: CONFIG.Thumbnail.Size.Width
        height: CONFIG.Thumbnail.Size.Height
        fill: true
    .then (img) ->
        callback()
    , (err) ->
        callback err

module.exports = (src, dst, type, callback) ->
    if type is 'image'
        createImageThumbnail src, dst, callback
    else if type is 'video'
        createVideoThumbnail src, dst, callback
    else
        throw new Error 'Unknown thumbnail type'