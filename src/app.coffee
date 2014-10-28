path = require 'path'

GLOBAL.APP_DIRECTORY    = __dirname;
GLOBAL.ROOT_DIRECTORY   = path.join(APP_DIRECTORY, '../')
GLOBAL.VIEW_DIRECTORY   = path.join(ROOT_DIRECTORY, 'views')
GLOBAL.PUBLIC_DIRECTORY = path.join(ROOT_DIRECTORY, 'public')

GLOBAL.CONFIG  = require('./config.json')
GLOBAL.LOGGING = require('./lib/logger')(CONFIG.LogFile)
GLOBAL.DB      = require('./lib/sqlite')(CONFIG.SQLiteFile)
GLOBAL.SERVER  = require('./lib/server')(CONFIG.Client.ListenPort)
GLOBAL.API     = require('./lib/api')(CONFIG.Client.Service)
GLOBAL.SCREEN  = require('./lib/screen')(CONFIG.Client.Service)