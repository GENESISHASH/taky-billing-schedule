# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
log = (x) -> try console.log x

_ = require 'lodash'

helpers = require '../src/lib/helpers'
Cycle = require '../src/module'

valid_opts = {
  cycle_seconds_human: '30 days'
  trial_seconds_human: '7 days'
  cycle_amount_dollars: '9.99'
  initial_amount_dollars: '12.00'
  initial_method: 'charge'
  after_trial_method: 'charge'
  after_trial_amount_dollars: '100'
  max_cycles: 0
}

invalid_opts = _.clone valid_opts
delete invalid_opts.cycle_amount_dollars

it 'should create a new object properly', (done) ->
  c = new Cycle valid_opts
  done() if helpers.type(c) is 'object'

it 'should return an error if the options are invalid', (done) ->
  cycle = new Cycle invalid_opts
  done() if helpers.type(cycle) is 'error'

it 'should produce an array of schedule objects', (done) ->
  cycle = new Cycle valid_opts
  queue = cycle.next 10
  done() if helpers.type(queue) is 'array' and queue.length

it 'should accept humanized output as valid new object input', (done) ->
  cycle = new Cycle valid_opts
  humanized = cycle.humanize()
  new_cycle = new Cycle humanized
  done() if helpers.type(new_cycle) isnt 'error'

it 'should show an initial_method charge as the first item', (done) ->
  cycle = new Cycle valid_opts
  first = _.first(cycle.next 1,1442289600)
  done() if first.reason is 'initial_method' and first.amount_cents is 1200

it 'should show after_trial charge as the first item', (done) ->
  opts = _.clone valid_opts
  opts.initial_method = 'none'
  cycle = new Cycle opts
  first = _.first(cycle.next 1,1442289600)
  done() if first.reason is 'after_trial' and first.amount_cents is 10000 

it 'should skip the initial_method because of the last_success time', (done) ->
  cycle = new Cycle valid_opts
  first = _.first(cycle.next 1,1442289600,1442289600)
  done() if first.reason is 'after_trial' and first.amount_cents is 10000

it 'should charge the after_trial and cycle amounts on the correct days, regardless of ctime and last_success', (done) ->
  cycle = new Cycle valid_opts

  after_trial = 1442289600 + (3600*24*7)
  first_cycle = 1442289600 + (3600*24*7)
  second_cycle = 1442289600 + (3600*24*37)

  queue = cycle.next 10, 1442289600,1442289600

  query = reason:'after_trial',time:after_trial,amount_cents:10000
  if !_.find(queue,query) 
    return done 'Failed to find correct after_trial charge in queue'

  query = reason:'cycle_0',time:first_cycle,amount_cents:999
  if !_.find(queue,query)
    return done 'Failed to find correct first cycle charge in queue'

  query = reason:'cycle_1',time:second_cycle,amount_cents:999
  if !_.find(queue,query)
    return done 'Failed to find correct second cycle charge in queue'

  done()

it 'should start with the second cycle (cycle_1) due to last_success time', (done) ->
  cycle = new Cycle valid_opts

  first_cycle = 1442289600 + (3600*24*7)
  second_cycle = 1442289600 + (3600*24*37)

  queue = cycle.next 10, 1442289600, first_cycle
  first = _.first queue

  if first.reason isnt 'cycle_1' or first.time isnt second_cycle or first.amount_cents isnt 999
    return done 'First queue item did not meet the expected requirements'

  done()

it 'should allow for an array of skippable unix time ranges', (done) ->
  cycle = new Cycle valid_opts

  first_cycle = 1442289600 + (3600*24*7)
  second_cycle = 1442289600 + (3600*24*37)

  queue = cycle.next 10, 1442289600, null, {
    skip_ranges: [
      [second_cycle,(second_cycle+1)]
    ]
  }

  query = {reason:'cycle_1'}
  done() if !_.find(queue,query)

it 'should allow for object argument in .next()', (done) ->
  cycle = new Cycle valid_opts

  opts =
    ctime: 1442289600
    last_success: null
    skip_ranges: null
    cycles_only: yes

  first = _.first(cycle.next 10, opts)

  done() if first.reason is 'cycle_0' and first.amount_cents is 999

