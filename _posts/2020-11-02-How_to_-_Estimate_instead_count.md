---
layout: post
title: How to … Estimate instead count(*)
excerpt: ''
date: 2020-11-02 12:02 +0100
modified: 2020-12-03 12:02 +0100
tags: [how_to, rails, pg]
comments: false
share: false
author: LeFnord
---


Again working on a frontend for visualizing a big amount of data, think you know the situation,
a kind of index view, or a GET all. So you start to implement something clever,
not to fetch all the data at once, ending up by a pagination or something similar
to utilise raw SQL `LIMIT` and `OFFSET` to speed things up.

This requires mostly the knowledge of the count of items,
so the `OFFSET` can be calculated correctly.

In following some log output for the count and select statements,
results table contains ~4,5M rows …

```shell
(129.8ms)  SELECT COUNT(*) FROM "results"
…
Result Load (0.4ms)  SELECT "results".* FROM "results" LIMIT $1 OFFSET $2  [["LIMIT", 100], ["OFFSET", 0]]
```

one can see that `COUNT` statement needs multiple times more then the `SELECT` statement.  
But do we need every time we are fetching the next span of data a new `COUNT`?

Think, NO.

### Separate endpoints for count and data fetching

Add another endpoint for getting the count only when its needed,
for example on page load.[^1]

```ruby
get 'count' do
  results = ::Result.filter(params)

  { count: results.count }
end

get 'filter' do
  limit = params[:limit] || 500
  offset = params[:offset] || 0
  results = ::Result.filter(params).limit(limit).offset(offset)

  { items: results }
end
```

Ok this results in an decreased count of executing of the count statement, cause of hitting the count endpoint only,
when parameters are changed, but doesn't speed it up.

## Estimate

By thinking and researching about, what can be improved,
I found this inspiring post [count-performance](https://www.citusdata.com/blog/2016/10/12/count-performance).

Ok, why not … the exact count isn't really needed, so I decided to give it a try.

### The Function

First we have to add a SQL function, which does the estimation.
For that, the function from the post above will be packed into a migration.

```ruby
class CreateEstimateFunction < ActiveRecord::Migration[6.0]
  def up
    function = "CREATE FUNCTION count_estimate(query text) RETURNS integer AS $$
      DECLARE
        rec   record;
        rows  integer;
      BEGIN
        FOR rec IN EXECUTE 'EXPLAIN ' || query LOOP
          rows := substring(rec.\"QUERY PLAN\" FROM ' rows=([[:digit:]]+)');
          EXIT WHEN rows IS NOT NULL;
        END LOOP;


        RETURN rows;
      END;
      $$ LANGUAGE plpgsql VOLATILE STRICT;"

    ActiveRecord::Base.connection.execute(function)
  end
end
```

Remember the name of the function (here: `count_estimate`) for later usage.

Now we have the function place, we should make usage of it.
So we are changing the endpoint into ...

```ruby
get 'count' do
  count = ::Result.counting(params)

  { count: count }
end
```

to call the new model method. Note, that it also take the same parameters as for filter endpoint.

```ruby
def self.filter(params)
  # filter implementation
  # returns an ActiveRecord::Relation object
end

def self.counting(params)
  query = if <search params given?>
            insert = ActiveRecord::Base.connection.quote(filter(params).to_sql)
            search_total_query(insert)
          else
            total_query
          end

  result = ActiveRecord::Base.connection.exec_query(query)
  result.rows.flatten.first.to_i
end

def self.search_total_query(query)
  "SELECT count_estimate(" + query + ");"
end

# helper methods
def self.total_query
  "SELECT
    (reltuples/relpages) * (pg_relation_size('results') /
    (current_setting('block_size')::integer)) AS count
  FROM pg_class where relname = 'results';"
end
```

To be consequent, we will use both estimations and decide via `search params given?`, which one to choose.
This is useful if want to make search queries which are decreasing the result space,
so the estimation want not differ too much.

For that the value of the `filter(params)` method have to be an `ActiveRecord::Relation` object,
so that we can reuse it here to generate the SQL string.

First some comparisions:

| timings  | count    | estimate |
|----------|----------|----------|
| no fiter | 116.8ms  | 0.7ms    |
|    fiter | 9130.1ms | 7.8ms    |
{: .table }

The difference is evident.


---

[^1]: For the examples I use [grape](https://github.com/ruby-grape/grape) mounted in a Rails project.
