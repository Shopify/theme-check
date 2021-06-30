# frozen_string_literal: true
module ThemeCheck
  class Analyzer
    def initialize(theme, checks = Check.all.map(&:new), auto_correct = false)
      @theme = theme
      @auto_correct = auto_correct

      @liquid_checks = Checks.new
      @json_checks = Checks.new
      @html_checks = Checks.new

      checks.each do |check|
        check.theme = @theme

        case check
        when LiquidCheck
          @liquid_checks << check
        when JsonCheck
          @json_checks << check
        when HtmlCheck
          @html_checks << check
        end
      end
    end

    def offenses
      @liquid_checks.flat_map(&:offenses) +
        @json_checks.flat_map(&:offenses) +
        @html_checks.flat_map(&:offenses)
    end

    def analyze_theme
      reset

      liquid_visitor = Visitor.new(@liquid_checks, @disabled_checks)
      html_visitor = HtmlVisitor.new(@html_checks)
      ThemeCheck.with_liquid_c_disabled do
        @theme.liquid.each do |template|
          liquid_visitor.visit_template(template)
          html_visitor.visit_template(template)
        end
      end

      @theme.json.each { |json_file| @json_checks.call(:on_file, json_file) }

      finish
    end

    def analyze_files(files)
      reset

      ThemeCheck.with_liquid_c_disabled do
        # Call all checks that run on the whole theme
        liquid_visitor = Visitor.new(@liquid_checks.whole_theme, @disabled_checks)
        html_visitor = HtmlVisitor.new(@html_checks.whole_theme)
        @theme.liquid.each do |template|
          liquid_visitor.visit_template(template)
          html_visitor.visit_template(template)
        end
        @theme.json.each { |json_file| @json_checks.whole_theme.call(:on_file, json_file) }

        # Call checks that run on a single files, only on specified file
        liquid_visitor = Visitor.new(@liquid_checks.single_file, @disabled_checks)
        html_visitor = HtmlVisitor.new(@html_checks.single_file)
        files.each do |file|
          if file.liquid?
            liquid_visitor.visit_template(file)
            html_visitor.visit_template(file)
          elsif file.json?
            @json_checks.single_file.call(:on_file, file)
          end
        end
      end

      finish
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

    private

    def reset
      @disabled_checks = DisabledChecks.new

      @liquid_checks.each do |check|
        check.offenses.clear
      end

      @html_checks.each do |check|
        check.offenses.clear
      end

      @json_checks.each do |check|
        check.offenses.clear
      end
    end

    def finish
      @liquid_checks.call(:on_end)
      @html_checks.call(:on_end)
      @json_checks.call(:on_end)

      @disabled_checks.remove_disabled_offenses(@liquid_checks)
      @disabled_checks.remove_disabled_offenses(@json_checks)
      @disabled_checks.remove_disabled_offenses(@html_checks)

      offenses
    end
  end
end
