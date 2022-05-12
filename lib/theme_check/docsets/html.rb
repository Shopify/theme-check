# frozen_string_literal: true

require 'json'

module ThemeCheck
  module Docsets
    module Html
      extend self

      def source
        @db ||= JSON.parse(
          File.read("#{__dir__}/../../../data/html.json"),
        )
      end

      def web_data
        @web_data ||= JSON.parse(
          File.read("#{__dir__}/../../../data/browsers.html-data.json"),
        )
      end

      def names
        @names ||= source.keys
          .select { |k| k.to_s.start_with?("element/") }
          .map { |n| n.sub("element/", "") }
      end

      def attributes(tag_name)
        tag = tags[tag_name.downcase]
        return [] unless tag
        tag["attributes"] + web_data["globalAttributes"]
      end

      def tags
        @tags || web_data["tags"]
          .map { |tag| [tag["name"], tag] }
          .to_h
      end

      def element_docs(name)
        source["element/#{name}"]
      end
    end
  end
end
