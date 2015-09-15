# taky-billing-schedule

# install

using [npm](https://npmjs.org)

```
npm i taky-billing-schedule --save
```

# example

``` coffeescript
Cycle = require 'taky-billing-schedule'

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

console.log cycle.next 10

###
[ { time: 1442350122,
    date: Tue Sep 15 2015 16:48:42 GMT-0400 (EDT),
    action: 'charge',
    reason: 'initial_method',
    amount_cents: 1200,
    amount_dollars: '12.00' },
  { time: 1442954922,
    date: Tue Sep 22 2015 16:48:42 GMT-0400 (EDT),
    action: 'charge',
    reason: 'after_trial',
    amount_cents: 10000,
    amount_dollars: '100.00' },
  { time: 1442954922,
    date: Tue Sep 22 2015 16:48:42 GMT-0400 (EDT),
    action: 'charge',
    reason: 'cycle_0',
    amount_cents: 999,
    amount_dollars: '9.99' },
  { time: 1445546922,
    date: Thu Oct 22 2015 16:48:42 GMT-0400 (EDT),
    action: 'charge',
    reason: 'cycle_1',
    amount_cents: 999,
    amount_dollars: '9.99' },
  { time: 1448138922,
    date: Sat Nov 21 2015 15:48:42 GMT-0500 (EST),
    action: 'charge',
    reason: 'cycle_2',
    amount_cents: 999,
    amount_dollars: '9.99' },
  { time: 1450730922,
    date: Mon Dec 21 2015 15:48:42 GMT-0500 (EST),
    action: 'charge',
    reason: 'cycle_3',
    amount_cents: 999,
    amount_dollars: '9.99' },
...
###
```

## .humanize()
return humanized output for cycle properties

## .next(num=1,created=null,last=null)
generate the next *num* scheduled items based on the cycle properties

