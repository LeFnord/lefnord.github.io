---
layout: post
title: How to … Minimise running Sidekiq jobs
excerpt: ''
date: 2020-10-20 00:15 +0200
modified: 2020-11-01 00:15 +0200
tags: [how_to, sidekiq]
comments: false
share: false
author: LeFnord
---

I'm working for a customer project, and stand for the task to build a view of many models[^1] —
yeap, the data model was/is a poor one —, so I came up, inspired
by this [post](https://pganalyze.com/blog/materialized-views-ruby-rails),
with [Scenic](https://github.com/scenic-views/scenic) to use a `materialized view` as solution.

All was fine, cause the data once imported will never change, only one thing to have in mind is,
refreshing the view after data import. Naming the model in this example `Result` ends up in this worker:

```ruby
class ResultRefreshJob
  include Sidekiq::Worker
  sidekiq_options queue: :views, retry: false

  def perform
    Result.refresh
  end
end
```

it calls the refresh method of our materialized view as it is documented
[here](https://github.com/scenic-views/scenic#what-about-materialized-views).

All fine, but some months later, a feature request comes in, to add another column.
Sounds after a low-hanging-fruit, but these data can occur `0..n` times and it ends up
in a flatten pivot table — presenting it as pivot table was not wanted —, means,
the data grows exponential with count of entries.
And a second problem was, the data can be changed, very quickly.

Its naïve to think the above solution can handle the boost of jobs,
which blocking itself.


> #### Goal
So the count of running jobs must be minimised  
and it have to be ensured the view is refreshed.

I came up with a second job, which checks if refresh jobs are running,
if not it enqueues a new one, and if one exists,
an error will be raised and it will be enqueued again.

It looks like following:
```ruby
class ResultEnqueueJob
  include Sidekiq::Worker
  sidekiq_options queue: :views, retry: 3

  # TODO: this should be observed and maybe adapted
  def perform
    running_worker = Sidekiq::Workers.new.map(&:last).select { |x| x['queue'] == 'views' }.last
    can_run = if running_worker
                run_at = DateTime.strptime("#{running_worker['run_at']}", '%s')
                run_at < DateTime.current - 1.minutes
              else
                true
              end

    if can_run
      ResultRefreshJob.perform_async
    else
      raise StandardError, "---> another ResultRefreshJob is running"
    end
  end
end
```

ok, looks quite simple, but what's the trick here?

We have here 3 parameters, number one the *retry count* (`rc`),
number two the *timespan we go back* (`ts`)
and number three, the unknown one, we can only estimate and observe,
the *time to rebuild the view* (`tr`).

The actual values are `tc = 3`, `ts = 1min` and we estimate `tr` to round `2min`,
now we have to optimize these values, to met the above goal and to adapt it on changes.

Have in mind, that the time to retry will exponential growing,
see: [automatic job retry](https://github.com/mperham/sidekiq/wiki/Error-Handling#automatic-job-retry).

Example:

t<sub>x</sub> : job<sub>1</sub> checks if can start → no job running, starts  
t<sub>x+ts</sub> : job<sub>2</sub> checks if can start → job<sub>1</sub> is running, can not  
t<sub>x+ts+30s</sub> : job<sub>2</sub>, checks again → job<sub>1</sub> is running, can not  
t<sub>x+ts+30s+46s</sub> : job<sub>2</sub>, checks again → job<sub>1</sub> finished, starts

---

[^1]: joining 6 tables, resulting in some 100m rows, this takes around 1-2min to perform
