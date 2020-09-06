---
layout: post
title: PG Fulltext Search outside of Rails
excerpt: ''
date: 2020-08-02 14:42 +0200
modified: 2020-09-06 02:30 +0200
tags: [pg, grape]
comments: true
share: true
author: LeFnord
---

I came across in a play project to want to implement a search functionality on a postgres text column.

For [Rails](https://rubyonrails.org) developers, there is a nice gem – [pg_search](https://github.com/Casecommons/pg_search) – out there, it does all what is needed for it.
But this is deeply bundled to Rails itself.

So I had to do it by hand, means:

  1. Understanding what it is and how is done in PG.
  2. How can this be integrated into my App?

#### For 1.

… this post [full-text-search-ruby-rails-postgres](https://pganalyze.com/blog/full-text-search-ruby-rails-postgres) is very informative for the beginning and understanding of the basics of the topic.

#### For 2.

For my app, it means a simple [grape](https://github.com/ruby-grape/grape) API, for the building of it [grape-starter](https://github.com/LeFnord/grape-starter) will be used. There I use [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) for accessing the database.

So that was the setup …

At the end of it, a model file exists, where the search will be implemented<sup>[1]</sup>.

```ruby
def self.search(query)
  find_by_sql([sql, query, query])
end
```

```ruby
def self.sql
  <<-SQL.strip_heredoc
    SELECT
      id,
      data,
      created_at,
      updated_at,
      ts_rank(
        to_tsvector(',language', 'data'),
        to_tsquery(',language', '<query>')
      ) AS rank
    FROM zettel
    WHERE
      to_tsvector(',language', 'data') @@
      to_tsquery(',language', '<query>')
    ORDER BY rank DESC
    LIMIT 3
  SQL
end
```

---
<sup>[1]</sup> IMHO … I personally prefer to split it up into two methods, first one – `search` – to accept the parameter and maybe doing something with it and provide it as input for the raw sql, and a second one – `query` – to represent in fact the raw SQL query, that will be called in the first method.
