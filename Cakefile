require('iced-coffee-script').register()
_ = require('wegweg')({globals:on,shelljs:on})

task 'test', (opts) ->
  exec """
    #{which 'mocha'} 
      --require iced-coffee-script/register -R spec test/test.iced
  """.split('\n').join(''), {async:on}

task 'build', ->
  cd __dirname

  await exec """
    iced --output dist --compile src
  """, defer()

  log "Finished"
  exit 1

