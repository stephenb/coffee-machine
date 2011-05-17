{exec} = require 'child_process'

task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  exec 'coffee --compile --output lib/ src/', (error, stdout, stderr) ->
    if error
      console.log "build failed: #{error}"
      throw error
    console.log "build complete. #{stdout} #{stderr}"

task 'test', 'Runs vowsjs test suite', ->
  exec './node_modules/vows/bin/vows test/test_state_machine.coffee --spec', (error, stdout, stderr) ->
    console.log stdout