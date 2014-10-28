sqlite3 = require('sqlite3').verbose()

module.exports = (db) ->
    return new sqlite3.Database db, (err) ->
        error err if err