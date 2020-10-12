---
layout: post
title: How To … Declare array parameters in grape
excerpt: ''
date: 2020-10-12 22:31 +0200
modified: 2020-10-12 22:31 +0200
tags: [how_to, grape]
comments: false
share: true
author: LeFnord
---

People are often confused about, *how to declare array parameters* in [grape](https://github.com/ruby-grape/grape) and represent it correct in the OpenAPI documentation via the [grape-swagger](https://github.com/ruby-grape/grape-swagger) gem.

For the example here an API skeleton will be build with [grape-starter](https://github.com/LeFnord/grape-starter), so in the result you have a running API app. There are two namespaces created, one for simple arrays and on for arrays of objects. For both POST and PUT endpoints will be implemented.

One thing to emphasize is the `param_type`, it is set to `body`, this is needed for JSON requests. If it will not be specified, a FormData parameter will be expected and documented.

# Array of simple Datatypes

The implementation self:


```ruby
namespace :arrays do
  params do
    optional :names, type: Array[String],
             documentation: { param_type: 'body' }
  end
  post do
    present :names, params[:names]
  end

  params do
    requires :id
  end
  route_param :id do
    params do
      optional :names, type: Array[String],
               documentation: { param_type: 'body' }
    end
    put do
      present :names, params[:names]
    end
  end
end
```

## usage

- POST request to: `/arrays`
- PUT request to: `/arrays/1`

with following JSON body:

```json
{
  "names": [
    "a", "b"
  ]
}
```


# Array of JSON objects

The implementation self:

```ruby
namespace :complex do
  params do
    requires :addresses, type: Array[JSON],
             documentation: { param_type: 'body' } do
               requires :street
               requires :city
               requires :code
             end
  end
  post do
    present :addresses, params[:addresses]
  end

  params do
    requires :id
  end
  route_param :id do
    params do
      requires :addresses, type: Array[JSON],
               documentation: { param_type: 'body' } do
                 requires :street
                 requires :city
                 requires :code
               end
    end
    put do
      present :addresses, params[:addresses]
    end
  end
end
```

## usage

- POST request to: `/complex`
- PUT request to: `/complex/1`

with following JSON body:

```json
{
  "addresses": [
    {
      "street": "some street a",
      "city": "city a",
      "code": "12345"
    }, {
      "street": "another street",
      "city": "city b",
      "code": "67890"
    }
  ]
}
```

The repo can be found [here](https://github.com/LeFnord/grape-arrays).
