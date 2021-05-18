# frozen_string_literal: true
module ThemeCheck
  class Analyzer
    def initialize(theme, checks = Check.all.map(&:new), auto_correct = false)
      @theme = theme
      @auto_correct = auto_correct

      @liquid_checks = Checks.new
      @json_checks = Checks.new

      checks.each do |check|
        check.theme = @theme

        case check
        when LiquidCheck
          @liquid_checks << check
        when JsonCheck
          @json_checks << check
        end
      end

      @visitor = Visitor.new(@liquid_checks)
    end

    def offenses
      @liquid_checks.flat_map(&:offenses) + @json_checks.flat_map(&:offenses)
    end

    def offenses_clear!
      @liquid_checks.each do |check|
        check.offenses.clear
      end

      @json_checks.each do |check|
        check.offenses.clear
      end
    end

    def analyze_theme
      if ThemeCheck.trace?
        ThemeCheck.trace("Analyzing theme ...")
        ThemeCheck.trace("#{@theme.all.size} files")
        ThemeCheck.trace("#{@theme.liquid.size} Liquid files")
        ThemeCheck.trace("#{@theme.json.size} JSON files")
      end
      ThemeCheck.trace("Analyzed theme") do
        offenses_clear!
        @theme.liquid.each { |template| @visitor.visit_template(template) }
        @theme.json.each { |json_file| @json_checks.call(:on_file, json_file) }
        @liquid_checks.call(:on_end)
        @json_checks.call(:on_end)
        offenses
      end
    end

    def uncorrectable_offenses
      unless @auto_correct
        return offenses
      end

      offenses.select { |offense| !offense.correctable? }
    end

    def correct_offenses
      if @auto_correct
        offenses.each(&:correct)
        @theme.liquid.each(&:write)
      end
    end
  end
end
