express = require 'express'
router = express.Router()

router.get '/', (req, res) ->
    res.render 'index'

router.control = require './control.js'
router.wall = require './wall.js'

module.exports = router