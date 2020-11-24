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
      @theme.all_files_paths.each { |template| analyze_template(template) }
      @checks.call(:on_end)
    end

    def analyze_template(template_path)
      template_path = Pathname(template_path)
      template = Liquid::Template.parse(
        template_path.read,
        line_numbers: true,
        disable_liquid_c_nodes: true
      )
      relative_template_path = template_path.relative_path_from(@theme.root)
      @visitor.visit_template(template, path: relative_template_path)
    end
  end
end
