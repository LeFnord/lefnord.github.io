---
layout: post
title: Rails/Grape — Kibana — Elasticsearch -> an Notebook of progress
excerpt: ''
date: 2020-06-03 00:33 +0200
modified: 2020-06-03 00:33 +0200
tags: [rails, grape, kibana]
comments: true
share: true
author: LeFnord
---

# Before

It is only a documentation of of a solution. It has no aspiration to be perfect, but can allways be improved.

# Goal

For a better bug investigation not only the logging of the App was needed,
these logs should be searcheable via web.

## Requirements

My customer has its own datacenter with limited access to outer services, for security reasons. The solution must be self-hostable, and for that, the code must be accessible, or a trustworthy provider must be found with an on-premise solution … 🤔

After a while of diving into this topic, it comes clear to me, that I should start with the logging itself …

# Logging

What should be logged, what is needed, what expected, what can help finding possible bugs … these questions are coming up by starting with it.

### Possible bugs or What can be improved?

Think on, you are working in a kind of scrum mode, means implementing a feature, and running the iterations over it. Some kinds of bugs/improvements are popping up. What can it be?

Maybe you worked on the front-end (FE), which needs and manipulates data, itself can/should not be logged (nor tracked), but you can observe the communication between them, the logging of `request-response-cycle` can be helpful by communication problems (btw have a look on the web console of your browser).

[first thoughts, published 06.09.202]

---
… updates by progress
