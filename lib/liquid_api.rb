# frozen_string_literal: true
require 'yaml'

module LiquidAPI
  module Filters
    extend self

    def labels
      @labels ||= begin
        YAML.load(File.read('data/liquid_api/filters.yml'))
          .values
          .flatten
      end
    end
  end
end
