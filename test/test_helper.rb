$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "theme_check"
require "minitest/autorun"
require "tmpdir"

module Minitest
  class Test
    def parse_liquid(code)
      Liquid::Template.parse(
        code,
        line_numbers: true,
        disable_liquid_c_nodes: true
      )
    end

    def analyze_theme(*check_classes, templates)
      analyzer = ThemeCheck::Analyzer.new(make_theme(templates), check_classes)
      analyzer.analyze_theme
      analyzer.offenses
    end

    def make_theme(templates)
      dir = Pathname.new(Dir.mktmpdir)
      templates.each_pair do |name, content|
        path = dir.join(name)
        path.parent.mkpath
        path.write(content)
      end
      at_exit { dir.rmtree }
      ThemeCheck::Theme.new(dir)
    end
  end
end
