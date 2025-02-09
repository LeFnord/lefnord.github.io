---
layout: post
title: How To … ViewComponents and Stimulus
excerpt: ''
date: 2025-02-09 17:42 +0100
modified: 2025-02-09 17:42 +0100
tags: [how_to, rails, stimulus, view_components]
comments: false
share: false
author: LeFnord
---

By using [ViewComponents](https://viewcomponent.org/guide/generators.html#generate-a-stimulus-controller)
one finds the possinility to also create a [Stimulus Controller](https://stimulus.hotwired.dev/reference/controllers).

It took a while for me to find it out, how to make us of it in a Rails 8 application,
together with [propshaft](https://github.com/rails/propshaft) and [importmaps](https://github.com/rails/importmap-rails).

At the end it was quite easy, simply add following:
```rb
# config/initializers/assets.rb
Rails.application.config.assets.paths << Rails.root.join("app/components")
Rails.application.config.importmap.cache_sweepers << Rails.root.join("app/components")
```
```rb
# config/importmap.rb
pin_all_from "app/components", under: "controllers", to: ""
```