#!/usr/bin/env ruby
# frozen_string_literal: true

# require 'active_support/core_ext/string'
# require 'pry'

def template
<<-FILE
---
layout: post
title: {{{title}}}
excerpt: ''
date: {{{datetime}}}
modified: {{{datetime}}}
tags: []
comments: false
share: false
author: LeFnord
---
FILE
end

date = Time.now.strftime("%F")
datetime = Time.now.strftime("%F %R %z")
title = ARGV.join(' ')
name = "#{date}-#{ARGV.join('_')}.md"

content = template.sub('{{{title}}}', title).gsub('{{{datetime}}}', datetime)

file_name = if Dir.entries(Dir.getwd).include?('_drafts')
  File.join(Dir.getwd, '_drafts', name)
else
  File.join(Dir.getwd, name)
end

File.open(file_name, 'w') {|f| f.write(content) }
