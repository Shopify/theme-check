# frozen_string_literal: true
$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "theme_check"
require "minitest/autorun"
require "mocha/minitest"
require "pry-byebug"
require "tmpdir"

module Minitest
  class Test
    def parse_liquid(code)
      ThemeCheck::Template.parse(code)
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
      @temp_themes ||= []
      @temp_themes << dir
      ThemeCheck::Theme.new(dir)
    end

    def teardown
      if defined?(@temp_themes)
        @temp_themes.each(&:rmtree)
      end
    end
  end
end
