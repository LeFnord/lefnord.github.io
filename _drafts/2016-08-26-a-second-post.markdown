---
layout: post
title: "a second post"
excerpt: '**TL;TR** Eu non nostrud culpa quis et qui aute ea elit deserunt officia.'
date: "2016-08-26 10:01:51 +0200"
modified: "2016-08-26 10:01:51 +0200"
comments: true
share: true
tags: [second, post]
---

yeap this would be a second post

Eu cillum mollit mollit voluptate tempor velit duis sit sint proident ad occaecat occaecat pariatur commodo pariatur occaecat. Proident sit elit laboris eiusmod ut reprehenderit id tempor et officia duis aute magna aute nisi. Amet quis eiusmod est irure enim enim sit velit fugiat sit sit aliqua officia occaecat cupidatat cillum anim.

Quis esse dolore id in deserunt elit eiusmod et minim ex eiusmod non incididunt amet. Dolore in dolor tempor id officia id nisi quis aute excepteur sunt nisi. Minim voluptate nulla ipsum commodo commodo occaecat dolor in ea dolor sunt nisi duis. Sint fugiat aliqua minim tempor laboris do do minim. Ea id culpa ipsum voluptate et irure est excepteur consectetur excepteur ex ad sit ut dolore laboris. Exercitation et deserunt eu adipisicing sunt consectetur labore enim magna non exercitation nostrud. Amet ex occaecat ipsum esse Lorem voluptate ut do ut quis proident aliquip.

Laborum minim minim irure laborum pariatur labore deserunt amet occaecat commodo. Consequat culpa cupidatat dolore nisi culpa aliquip dolore reprehenderit eu veniam pariatur voluptate non velit. Ea cupidatat sit duis Lorem veniam tempor velit id sint ipsum consequat ut.

Proident amet fugiat enim eiusmod ex magna id aliqua consectetur et adipisicing Lorem duis sit exercitation. Aliquip aliquip minim elit nisi aute cupidatat Lorem excepteur reprehenderit. Commodo pariatur nulla est sunt labore magna fugiat veniam esse magna qui. Ex mollit ad mollit dolor fugiat sint sunt officia reprehenderit do culpa sunt ut. Culpa exercitation pariatur duis sit commodo culpa deserunt cupidatat officia. Laborum velit velit laboris consectetur esse aliquip sunt eiusmod anim eu minim occaecat consectetur elit excepteur.

```ruby
require 'rake'
require 'rake/tasklib'
require 'rack/test'

module Starter
  module Rake
    class GrapeTasks < ::Rake::TaskLib
      include Rack::Test::Methods

      attr_reader :swagger

      def api_class
        Api::Base
      end

      def initialize
        super
        define_tasks
      end

      def api_routes
        api_class.routes.each_with_object([]) do |route, memo|
          memo << { verb: route.request_method, path: build_path(route), description: route.description }
        end
      end

      private

      def define_tasks
        namespace :grape do
          swagger
          routes
          validate
        end
      end

      # tasks
      #
      # get swagger/OpenAPI documentation
      def swagger
        desc 'generates OpenApi documentation (`store=true`, stores to FS)'
        task swagger: :environment do
          file = File.join(Dir.getwd, file_name)

          make_request
          ENV['store'] ? File.write(file, @swagger) : print(@swagger)
        end
      end

      # show API routes
      def routes
        desc 'shows all routes'
        task routes: :environment do
          print_routes api_routes
        end
      end

      def validate
        desc 'validates the generated OpenApi file'
        task validate: :environment do
          ENV['store'] = 'true'
          ::Rake::Task['grape:swagger'].invoke

          a = system "swagger validate #{file_name}"

          $stdout.puts 'install swagger-cli with `npm install swagger-cli -g`' if a.nil?
        end
      end

      # helper methods
      #
      def make_request
        get url_for
        last_response
        @swagger = JSON.pretty_generate(
          JSON.parse(
            last_response.body, symolize_names: true
          )
        )
      end

      def url_for
        swagger_route = api_class.routes[-2]
        url = '/swagger_doc'
        url = "/#{swagger_route.version}#{url}" if swagger_route.version
        url = "/#{swagger_route.prefix}#{url}" if swagger_route.prefix
        url
      end

      def file_name
        'swagger_doc.json'
      end

      def app
        api_class.new
      end

      def print_routes(routes_array)
        routes_array.each do |route|
          puts "\t#{route[:verb].ljust(7)}#{route[:path].ljust(42)}#{route[:description]}"
        end
      end

      def build_path(route)
        path = route.path

        path.sub!(/\(\.\w+?\)$/, '')
        path.sub!('(.:format)', '')

        if route.version
          path.sub!(':version', route.version.to_s)
        else
          path.sub!('/:version', '')
        end

        path
      end
    end
  end
end
```
