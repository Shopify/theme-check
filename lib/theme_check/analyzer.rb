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

    def json_file_count
      @json_file_count ||= @theme.json.size
    end

    def liquid_file_count
      @liquid_file_count ||= @theme.liquid.size
    end

    def total_file_count
      json_file_count + liquid_file_count
    end

    def analyze_theme
      reset

      liquid_visitor = LiquidVisitor.new(@liquid_checks, @disabled_checks)
      html_visitor = HtmlVisitor.new(@html_checks)

      ThemeCheck.with_liquid_c_disabled do
        @theme.liquid.each_with_index do |liquid_file, i|
          yield(liquid_file.relative_path.to_s, i, total_file_count) if block_given?
          liquid_visitor.visit_liquid_file(liquid_file)
          html_visitor.visit_liquid_file(liquid_file)
        end
      end

      @theme.json.each_with_index do |json_file, i|
        yield(json_file.relative_path.to_s, liquid_file_count + i, total_file_count) if block_given?
        @json_checks.call(:on_file, json_file)
      end

      finish
    end

    def analyze_files(files, only_single_file: false)
      reset

      ThemeCheck.with_liquid_c_disabled do
        total = files.size
        offset = 0

        unless only_single_file
          # Call all checks that run on the whole theme
          liquid_visitor = LiquidVisitor.new(@liquid_checks.whole_theme, @disabled_checks)
          html_visitor = HtmlVisitor.new(@html_checks.whole_theme)
          total += total_file_count
          offset = total_file_count
          @theme.liquid.each_with_index do |liquid_file, i|
            yield(liquid_file.relative_path.to_s, i, total) if block_given?
            liquid_visitor.visit_liquid_file(liquid_file)
            html_visitor.visit_liquid_file(liquid_file)
          end

          @theme.json.each_with_index do |json_file, i|
            yield(json_file.relative_path.to_s, liquid_file_count + i, total) if block_given?
            @json_checks.whole_theme.call(:on_file, json_file)
          end
        end

        # Call checks that run on a single files, only on specified file
        liquid_visitor = LiquidVisitor.new(@liquid_checks.single_file, @disabled_checks)
        html_visitor = HtmlVisitor.new(@html_checks.single_file)
        files.each_with_index do |theme_file, i|
          yield(theme_file.relative_path.to_s, offset + i, total) if block_given?
          if theme_file.liquid?
            liquid_visitor.visit_liquid_file(theme_file)
            html_visitor.visit_liquid_file(theme_file)
          elsif theme_file.json?
            @json_checks.single_file.call(:on_file, theme_file)
          end
        end
      end

      finish(only_single_file)
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
      end
    end

    def write_corrections
      if @auto_correct
        @theme.liquid.each(&:write)
        @theme.json.each(&:write)
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

    def finish(only_single_file = false)
      if only_single_file
        @liquid_checks.single_file.call(:on_end)
        @html_checks.single_file.call(:on_end)
        @json_checks.single_file.call(:on_end)
      else
        @liquid_checks.call(:on_end)
        @html_checks.call(:on_end)
        @json_checks.call(:on_end)
      end

      @disabled_checks.remove_disabled_offenses(@liquid_checks)
      @disabled_checks.remove_disabled_offenses(@json_checks)
      @disabled_checks.remove_disabled_offenses(@html_checks)

      offenses
    end
  end
end
