# frozen_string_literal: true
module ThemeCheck
  class Analyzer
    attr_reader :offenses

    def initialize(theme, check_classes = Check.all)
      @theme = theme
      @offenses = []

      @checks = Checks.new
      check_classes.each do |check_class|
        check = check_class.new
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
