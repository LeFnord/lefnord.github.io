---
layout: post
title: How To … Searchkick
excerpt: ''
date: 2021-11-06 08:09 +0100
modified: 2021-11-10 08:09 +0100
tags: [how_to, searchkick]
comments: false
share: true
author: LeFnord
---

Working with [Are.na](https://www.are.na) on upgrading, or better replacing,
the search infrastructure, meaning from [ElasticSearch](https://www.elastic.co/) 1.7.x together
with [re|tire](https://github.com/karmi/retire) to use [OpenSearch](https://www.opensearch.org)
with [Searchkick](https://github.com/ankane/searchkick).

In this process we found some unexpected solutions, for existend behaviour.
Unexpected because they are not documented. Here we want to share these finding.


## Findings

### 1 Mixing

According to the [Searchkick](https://github.com/ankane/searchkick#partial-matches) documentation,
you have several possibilities to influence the search behavior, by specifying the analyzer to use,
so for our example with

```ruby
class Product < ApplicationRecord
  searchkick text_middle: [:name],
             word_start: [:content]
end
```

and use then the same setting in the `match` field … 🤔

But we wanted to search for both fields at once.
This was not documented, so we had to dive into the code (→ [idea](https://github.com/ankane/searchkick/blob/0d18831ae96988ed7089ffc85cd0ee36952ce254/lib/searchkick/query.rb#L360)),
where the field option will be evaluated, so it seems an Array of Hashes will be accepted.

The solution is, to provide for each field the appropiated analyzer.

```ruby
Product.search query, fields: [
  { 'name^3': :text_middle }, # use togehter with boost
  { content: :word_start },
]
```

> By using this method, avoid using the `match` key, cause it overwrites above analyzers.

### 2 Settings

Above we saw how to use the options. But what are these options?
That are [shortcuts](https://github.com/ankane/searchkick/blob/0d18831ae96988ed7089ffc85cd0ee36952ce254/lib/searchkick/index_options.rb#L38)
for predefined Anlayzers, to use for processing the String/Text on indexing.

One can see, that each of them is built up the three keys `type`, `tokenizer` and `filter`.
It specifies the [Analysis](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis.html), which should be applied to this field.

Another finding are the sizes of the `min_gram` and `max_gram`.
They are good for most cases, as are all predefined analyzers.
But we wanted to change it to our needs, cause our content can be a very long description,
so using a `max_ngram` of 50, will result in a very big index,
without improving the search quality itself.

So we have to adapt it to our needs, and yes you guessed it … 😉
But the [seetings](https://github.com/ankane/searchkick/blob/0d18831ae96988ed7089ffc85cd0ee36952ce254/lib/searchkick/index_options.rb#L184) are used, so it must be possible to specify them as well.
With a little trial and error, we found it

```ruby
Searchkick.model_options = {
  settings: {
    analysis: {
      filter: {
        searchkick_edge_ngram: { type: 'edge_ngram', min_gram: 1, max_gram: 17 },
        searchkick_ngram: { type: 'ngram', min_gram: 1, max_gram: 17 }
      }
    },
    index: {
      max_ngram_diff: 23
    }
  }
}
```

But what, if we want to define our own analyzer?

> It must be said that this is not recommended, unless you know exactly what you are doing, because as already said, the available are very good and sufficient for most cases.

Ok, one can not add own ones the [predefined analyzer](https://github.com/ankane/searchkick/blob/0d18831ae96988ed7089ffc85cd0ee36952ce254/lib/searchkick/index_options.rb#L38) list.
But one can overwrite an existend one … for example changing the above `text_middle` analyzer

```ruby
Searchkick.model_options = {
  settings: {
    analysis: {
      analyzer: {
        searchkick_text_middle_index: {
          type: 'custom',
          tokenizer: 'whitespace',
          filter: %w[lowercase snowball_german_umlaut unique name_ngram]
        },
      },
      filter: {
        name_ngram: { type: 'ngram', min_gram: 1, max_gram: 3, preserve_original: true },
        snowball_german_umlaut: { type: 'snowball', name: 'German2' },
      }
    }
  }
}
```

it doesn't make so much sense, but you get the idea.
For possible Analyzer options refer to the
[Analysis](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis.html)
documentation.

By the way, it also works with OpenSearch, but actual the [ES documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis.html), especially the [Lucene](https://lucene.apache.org) related one is much better.


> Don't forget to reindex each time, after one of the obove settings are changed!
