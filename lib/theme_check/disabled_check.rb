# frozen_string_literal: true

# This class keeps track of checks being turned on and off in ranges.
# We'll use the node position to figure out if the test is disabled or not.
module ThemeCheck
  class DisabledCheck
    attr_reader :name, :ranges
    attr_accessor :first_line

    def initialize(name)
      @name = name
      @ranges = []
      @first_line = false
    end

    def start_index=(index)
      return unless ranges.empty? || !last.end.nil?
      @ranges << (index..)
    end

    def end_index=(index)
      return if ranges.empty? || !last.end.nil?
      @ranges << (@ranges.pop.begin..index)
    end

    def disabled?(index)
      ranges.any? { |range| range.cover?(index) }
    end

    def last
      ranges.last
    end

    def missing_end_index?
      return false if first_line && ranges.size == 1
      last.end.nil?
    end
  end
end
