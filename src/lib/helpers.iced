# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
log = (x) -> try console.log x

_ = require 'lodash'

HumanTime = require 'custom-human-time'
human_interval = require 'human-interval'

# helper functions for converting values
module.exports = helpers =

  time: -> Math.round new Date().getTime() / 1000

  type: (obj) ->
    return no if obj is 'undefined' or obj is null                                          
    Object::toString.call(obj).slice(8, -1).toLowerCase() 

  # convert expression to seconds
  to_seconds: (str) ->
    replace = {
      yr: 'year'
      mo: 'month'
      wk: 'week'
      sec: 'second'
    }

    for k,v of replace
      if str.indexOf(k) > -1 and !(str.indexOf(v) > -1)
        str = str.split(k).join(v)

    str = str.trim()

    try
      Math.round human_interval(str)/1000
    catch
      return new Error 'Time description "' + str + '" could not be parsed'

  # convert seconds to human expression
  to_human: (secs) ->
    secs = +secs

    times = [
      secs / 60 / 60 / 24 / 365
      secs / 60 / 60 / 24 / 30
      secs / 60 / 60 / 24
      secs / 60 / 60
      secs / 60
      secs
    ]

    labels = [
      'year'
      'month'
      'day'
      'hour'
      'minute'
      'second'
    ]

    results = {}

    i = 0

    for label in labels
      results[label] = times[i]
      ++ i

    for label,count of results
      if count >= 1
        if count is 1
          singular = yes
        else
          singular = no
          if count.toString().indexOf('.') > -1
            count = count.toFixed 1
          else
            count = count

        return str = [
          count
          label + (if !singular then 's' else '')
        ].join ' '

    return new Error 'Failed to convert seconds to human format'

  to_dollars: (str) ->
    num = @clean_number str
    (num / 100).toFixed 2

  to_cents: (str) ->
    num = @clean_number str
    num * 100

  clean_number: (str) ->
    if typeof str isnt 'string'
      str = str.toString()

    allowed = [0..9].concat(['.']).join('').split ''

    clean = _.compact _.map (str.split ''), (item) ->
      item if item in allowed

    clean = clean.join ''
    parseFloat clean

