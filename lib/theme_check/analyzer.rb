# frozen_string_literal: true
module ThemeCheck
  class Analyzer
    attr_reader :offenses

    def initialize(theme, checks = Check.all.map(&:new))
      @theme = theme
      @offenses = []

      @checks = Checks.new
      checks.each do |check|
        check.theme = @theme
        check.offenses = @offenses
        @checks << check
      end

      @visitor = Visitor.new(@checks)
    end

    def analyze_theme
      @theme.all.each { |template| analyze_template(template) }
      @checks.call(:on_end)
    end

    def analyze_template(template)
      @visitor.visit_template(template)
    end
  end
end
