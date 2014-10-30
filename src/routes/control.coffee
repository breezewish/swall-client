express = require 'express'
router = express.Router()

router.get '/', (req, res) ->
    res.render 'control/index'

responseHandler = (req, res, next) ->
    (err, data) ->
        return next err if err
        if data?
            res.json data
        else
            res.json {}

router.get '/screen/info/:id', (req, res, next) ->
    API.get "/#{req.params.id}/info", responseHandler(req, res, next)

router.get '/screen/status', (req, res, next) ->
    SCREEN.getStatus responseHandler(req, res, next)

router.post '/screen/connect/:id', (req, res, next) ->
    SCREEN.connect req.params.id, responseHandler(req, res, next)

router.post '/assets/reveal', (req, res, next) ->
    SCREEN.revealAssets responseHandler(req, res, next)

router.post '/assets/scan', (req, res, next) ->
    SCREEN.scanAssets responseHandler(req, res, next)

router.post '/assets/:hash/modify', (req, res, next) ->
    SCREEN.updateAssetDesc req.params.hash, req.body.description, responseHandler(req, res, next)

router.post '/wall/switch/:hash', (req, res, next) ->
    SCREEN.switchToAsset req.params.hash, responseHandler(req, res, next)

router.post '/wall/show', (req, res, next) ->
    SCREEN.setDanmakuVisibility true, responseHandler(req, res, next)

router.post '/wall/hide', (req, res, next) ->
    SCREEN.setDanmakuVisibility false, responseHandler(req, res, next)

router.post '/wall/settings', (req, res, next) ->
    SCREEN.updateDanmakuSettings req.body.duration, req.body.maxline, responseHandler(req, res, next)

router.post '/wall/asset/repeat', (req, res, next) ->
    SCREEN.updateAssetsRepeat req.body.repeat, responseHandler(req, res, next)

router.post '/wall/comment', (req, res, next) ->
    SCREEN.comment req.body, responseHandler(req, res, next)

router.post '/filter', (req, res, next) ->
    SCREEN.setFilter responseHandler(req, res, next)

module.exports = router