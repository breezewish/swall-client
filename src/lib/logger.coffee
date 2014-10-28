winston = require 'winston'
winston.exitOnError = false
winston.remove winston.transports.Console
winston.add winston.transports.Console,
    colorize:   process.stdout.isTTY
    timestamp:  true

# expose logging functions to global
GLOBAL[method] = winston[method] for method in ['info', 'warn', 'error']

module.exports = (logfile) ->
    winston.add winston.transports.File, filename: logfile