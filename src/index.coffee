# module 
http = require 'http'
express = require 'express'
sysPath = require "path"

# local module
helper = require "./helper"


# defaults options
processOptions = (options) ->
  helper.merge options, 
    # listener port
    port:8000
    # auto-reload  
    reload:true
    # working folder
    dir:process.cwd()
    # autemate launch browser
    launch:true
    # plugins (generally, will be some route-rules, see src/addons folder to get help)
    addon:null
    # ignored watching type
    matches:['\\.(js|css|html|htm|xhtml|md|markdown|txt|hbs|jade)$']
    # add watching file *tips:excludes has a priority higher than ex 
    excludes:['node_modules']

# solve network port conflict TODO: 这太丑了
restarted = 0
startServer = (server, port, callback) ->
  try
    server.listen port, callback
  catch e
    # max-time 100
    if restarted < 100 then startServer server, port + (++restarted), callback
    else throw e

module.exports = (options = {}) ->
      # pre options
      processOptions(options)

      app = do express
      server = http.createServer app
      # init autoreload
      (require "./autoreload") app, server, options if options.reload
      
      # inject addon
      addon app, server, options for own key, addon of helper.requireFolder sysPath.join __dirname, "./addons"
      require(options.addon) app, server, options if options.addon
      # config express 
      app.configure ->
        # first search lib related static folder
        app.use express.static options.dir  
        # then customer's folder
        app.use express.static sysPath.join __dirname, "..", "vendor"  

      #  start the server
      startServer server, options.port, ->
        console.log "server start at localhost:#{options.port}"
        if options.launch
          (require "open") "http://localhost:#{options.port}"
          console.log "puer will launch your browser later"

