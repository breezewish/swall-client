express = require 'express'
router = express.Router()

router.get '/', (req, res) ->
    res.render 'wall/index'

responseHandler = (req, res, next) ->
    (err, data) ->
        return next err if err
        if data?
            res.json data
        else
            res.json {}

router.get '/preference', (req, res, next) ->
    SCREEN.getWallPreference responseHandler(req, res, next)

module.exports = router