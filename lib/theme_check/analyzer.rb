# frozen_string_literal: true
module ThemeCheck
  class Analyzer
    attr_reader :offenses

    def initialize(theme, checks = Check.all.map(&:new))
      @theme = theme
      @offenses = []

      @liquid_checks = Checks.new
      @json_checks = Checks.new

      checks.each do |check|
        check.theme = @theme
        check.offenses = @offenses

        case check
        when LiquidCheck
          @liquid_checks << check
        when JsonCheck
          @json_checks << check
        end
      end

      @visitor = Visitor.new(@liquid_checks)
    end

    def analyze_theme
      @theme.liquid.each { |template| @visitor.visit_template(template) }
      @theme.json.each { |json_file| @json_checks.call(:on_file, json_file) }
      @liquid_checks.call(:on_end)
      @json_checks.call(:on_end)
    end

    def analyze_file(path)
      path = Pathname.new(path)
      analyze_theme
      @offenses.reject! { |offense| offense.template.path != path }
    end
  end
end
