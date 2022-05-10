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

      def names
        @names ||= source.keys
          .select { |k| k.to_s.start_with?("element/") }
          .map { |n| n.sub("element/", "") }
      end

      def element_docs(name)
        source["element/#{name}"]
      end
    end
  end
end
