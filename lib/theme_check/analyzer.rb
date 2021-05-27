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
      offenses_clear!

      disabled_checks = DisabledChecks.new

      visitor = Visitor.new(@liquid_checks, disabled_checks)
      @theme.liquid.each { |template| visitor.visit_template(template) }
      @theme.json.each { |json_file| @json_checks.call(:on_file, json_file) }

      @liquid_checks.call(:on_end)
      @json_checks.call(:on_end)

      disabled_checks.remove_disabled_offenses(@liquid_checks)
      disabled_checks.remove_disabled_offenses(@json_checks)

      offenses
    end

    def analyze_files(files)
      offenses_clear!

      disabled_checks = DisabledChecks.new

      # Call all checks that run on the whole theme
      visitor = Visitor.new(@liquid_checks.whole_theme, disabled_checks)
      @theme.liquid.each { |template| visitor.visit_template(template) }
      @theme.json.each { |json_file| @json_checks.whole_theme.call(:on_file, json_file) }

      # Call checks that run on a single files, only on specified file
      visitor = Visitor.new(@liquid_checks.single_file, disabled_checks)
      files.each do |file|
        if file.liquid?
          visitor.visit_template(file)
        elsif file.json?
          @json_checks.single_file.call(:on_file, file)
        end
      end

      @liquid_checks.call(:on_end)
      @json_checks.call(:on_end)

      disabled_checks.remove_disabled_offenses(@liquid_checks)
      disabled_checks.remove_disabled_offenses(@json_checks)

      offenses
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
