# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
log = (x) -> try console.log x

_ = require 'lodash'
mongoose = require 'mongoose'

helpers = require './lib/helpers'

# input schema
Schema = new mongoose.Schema {
  
  # number of seconds between cycles
  cycle_seconds:
    type: Number
    required: yes

  # number of seconds before cycle starts
  trial_seconds:
    type: Number
    required: yes
    default: 0

  initial_amount_cents:
    type: Number
    required: yes
    default: 0

  initial_method:
    type: String
    enum: [
      'none'
      'authorize_void'
      'charge'
    ]
    required: yes
    default: 'none'

  # charged after the trial expires as the cycle starts
  after_trial_method:
    type: String
    enum: [
      'none'
      'charge'
    ]
    required: yes
    default: 'none'

  after_trial_amount_cents:
    type: Number
    required: yes
    default: 0

  # amount (cents) to be charged each cycle
  cycle_amount_cents:
    type: Number
    required: yes

  # maximum amount of cycles to bill
  max_cycles:
    type: Number
    required: yes
    default: 0
}

# return humanized output
Schema.methods.humanize = ->
  clone = @toJSON()

  # add human times
  for k,v of clone
    if k.indexOf('_seconds') > -1
      if v
        check = (clone[k + '_human'] = helpers.to_human v)
        return check if helpers.type(check) is 'error'

    if k.indexOf('_cents') > -1
      if v
        check = (clone[k.replace('_cents','_dollars')] = helpers.to_dollars v)
        return check if helpers.type(check) is 'error'

  clone

# calculate the next $num scheduled actions
Schema.methods.next = (num_items=1,ctime=null,last_success=null,options={}) ->
  if ctime and helpers.type(ctime) is 'object'
    clone = _.clone ctime

    last_success = clone.last_success ? null
    ctime = clone.ctime ? null

    options.max_time = clone.max_time ? no
    options.skip_ranges = clone.skip_ranges ? null
    options.skip_cycles = clone.skip_cycles ? null
    options.cycles_only = clone.cycles_only ? null

  if options.skip_cycles and helpers.type(options.skip_cycles) isnt 'array'
    options.skip_cycles = [options.skip_cycles]

  last_success = +last_success if last_success

  skip_ranges = []
  skip_cycles = []

  if options.skip_ranges
    skip_ranges.push x for x in options.skip_ranges

  if options.skip_cycles
    skip_cycles.push (+x) for x in options.skip_cycles

  if options.max_time and helpers.type(options.max_time) in ['string','number']
    max_time = (+options.max_time)
  else
    max_time = no

  if ctime
    ctime = +ctime
  else
    ctime = helpers.time()

  template = {
    time: null
    date: null
    action: null
    reason: null
    amount_cents: null
    amount_dollars: null
  }

  actions = []

  # push initial action if this is a new cycle object
  if (@initial_method isnt 'none' and !last_success) and !options.cycles_only
    initial = _.clone template
    initial.amount_cents = @initial_amount_cents
    initial.action = @initial_method
    initial.reason = 'initial_method'
    initial.time = ctime

    actions.push initial

  # set the cursor to the creation time of the cycle
  cursor = ctime
  cursor_cycle = 0

  # account for the trial time if there was a trial
  if @trial_seconds
    cursor += @trial_seconds

    if (!last_success or last_success < cursor) and !options.cycles_only
      if @after_trial_method isnt 'none'
        after_trial = _.clone template
        after_trial.amount_cents = @after_trial_amount_cents
        after_trial.action = 'charge'
        after_trial.reason = 'after_trial'
        after_trial.time = cursor

        actions.push after_trial

  # catch the cursor up to the last successful transaction
  if last_success and last_success >= cursor
    while cursor <= last_success
      cursor += @cycle_seconds
      cursor_cycle += 1

  while actions.length < num_items
    cycle_charge = _.clone template
    cycle_charge.amount_cents = @cycle_amount_cents
    cycle_charge.action = 'charge'
    cycle_charge.reason = 'cycle_' + cursor_cycle
    cycle_charge.cycle_int = cursor_cycle
    cycle_charge.time = cursor

    # determine if we should skip this action due to options.skip_ranges
    # or options.skip_cycles
    skip_action = no

    if skip_ranges.length
      for range in skip_ranges
        if cursor >= range[0] and cursor <= range[1]
          skip_action = yes
          break

    if skip_cycles.length
      if cursor_cycle in skip_cycles
        skip_action = yes

    if max_time and cursor > max_time
      break

    if !skip_action
      actions.push cycle_charge

    cursor += @cycle_seconds
    cursor_cycle += 1

  # append date objects and dollar amounts to the actions array
  actions = _.map actions, (item) ->
    item.date = new Date item.time * 1000
    item.amount_dollars = helpers.to_dollars item.amount_cents
    item

  actions

# extend schema with helper functions as static methods
for fn in _.functions(helpers)
  Schema.statics[fn] = helpers[fn]

Model = mongoose.model 'Cycle', Schema

# primary export, model wrapper
module.exports = Cycle = (opt) ->

  # allow humanized inputs
  for k,v of opt
    if k.indexOf('_seconds_human') > -1
      check = (opt[k.replace('_seconds_human','_seconds')] = helpers.to_seconds v)
      return check if helpers.type(check) is 'error'

  # dollars/cents helper
  for k,v of opt
    if k.indexOf('_dollars') and !opt[(cents_key = k.replace('_dollars','_cents'))]
      check = (opt[cents_key] = helpers.to_cents v)
      return check if helpers.type(check) is 'error'

  # create model, run validation
  model = new Model opt

  err = model.validateSync()

  if err?.errors
    return new Error(_.values(err.errors).toString())

  model

###
cycle = new Cycle {
  cycle_seconds_human: '30 days'
  trial_seconds_human: '7 days'
  cycle_amount_dollars: '9.99'
  initial_amount_dollars: '12.00'
  initial_method: 'charge'
  after_trial_method: 'charge'
  after_trial_amount_dollars: '100'
  max_cycles: 0
}

log cycle.next 10
###

