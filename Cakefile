require('iced-coffee-script').register()
_ = require 'taky'

task 'test', (opts) ->
  exec """
    #{which 'mocha'} 
      --compilers iced:iced-coffee-script/register -R spec
  """.split('\n').join(''), {async:on}

task 'build', ->
  cd __dirname

  await exec """
    iced --output dist --compile src
  """, defer()

  log "Finished"
  exit 1

