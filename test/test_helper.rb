# frozen_string_literal: true
$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "theme_check"
require "minitest/autorun"
require "minitest/focus"
require "mocha/minitest"
require "pry-byebug"
require "tmpdir"

module Minitest
  class Test
    def parse_liquid(code)
      storage = make_storage("file.liquid" => code)
      ThemeCheck::Template.new("file.liquid", storage)
    end

    def liquid_c_enabled?
      defined?(Liquid::C) && Liquid::C.enabled
    end

    def analyze_theme(*check_classes, templates)
      analyzer = ThemeCheck::Analyzer.new(make_theme(templates), check_classes)
      analyzer.analyze_theme
      analyzer.offenses
    end

    def make_theme(files = {})
      storage = make_storage(files)
      ThemeCheck::Theme.new(storage)
    end

    def make_storage(files = {})
      return make_file_system_storage(files) if ENV['THEME_STORAGE'] == 'FileSystemStorage'
      make_in_memory_storage(files)
    end

    def make_file_system_storage(files = {})
      dir = Pathname.new(Dir.mktmpdir)
      files.each_pair do |name, content|
        path = dir.join(name)
        path.parent.mkpath
        path.write(content)
      end
      at_exit { dir.rmtree }
      ThemeCheck::FileSystemStorage.new(dir)
    end

    def make_in_memory_storage(files = {})
      ThemeCheck::InMemoryStorage.new(files)
    end

    def fix_theme(*check_classes, templates)
      theme = make_theme(templates)
      analyzer = ThemeCheck::Analyzer.new(theme, check_classes, true)
      analyzer.analyze_theme
      analyzer.correct_offenses
      sources = theme.liquid.map { |template| [template.relative_path.to_s, template.updated_content] }
      Hash[*sources.flatten]
    end

    def assert_offenses(output, offenses)
      # Making sure nothing blows up in the language_server
      offenses.each do |offense|
        assert(offense.start_line)
        assert(offense.start_column)
        assert(offense.end_line)
        assert(offense.end_column)
      end

      assert_equal(output.chomp, offenses.sort_by(&:location).join("\n"))
    end

    def assert_includes_offense(offenses, output)
      assert_includes(offenses.sort_by(&:location).join("\n"), output.chomp)
    end

    module CompletionProviderTestHelper
      def assert_can_complete(provider, token, offset = 0)
        refute_empty(
          provider.completions(token, token.size + offset).map { |x| x[:label] },
          <<~ERRMSG,
            Expected completions at the specified cursor position:
            #{token}
            #{' ' * (token.size + offset)}^
          ERRMSG
        )
      end

      def assert_can_complete_with(provider, token, label, offset = 0)
        assert_includes(
          provider.completions(token, token.size + offset).map { |x| x[:label] },
          label,
          <<~ERRMSG,
            Expected '#{label}' to be suggested at the specified cursor position:
            #{token}
            #{' ' * (token.size + offset)}^
          ERRMSG
        )
      end

      def refute_can_complete(provider, token, offset = 0)
        assert_empty(
          provider.completions(token, token.size + offset),
          <<~ERRMSG,
            Expected no completions at the specified cursor location:
            #{token}
            #{' ' * (token.size + offset)}^
          ERRMSG
        )
      end

      def refute_can_complete_with(provider, token, label, offset = 0)
        refute_includes(
          provider.completions(token, token.size + offset).map { |x| x[:label] },
          label,
          <<~ERRMSG,
            Expected '#{label}' not to be suggested at the specified cursor position:
            #{token}
            #{' ' * (token.size + offset)}^
          ERRMSG
        )
      end
    end

    class TracerCheck < ThemeCheck::Check
      attr_reader :calls

      def initialize
        @calls = []
      end

      def respond_to?(method)
        method.to_s.start_with?("on_") || method.to_s.start_with?("after_") || super
      end

      def method_missing(method, node)
        @calls << method
        @calls << node.value if node.literal?
      end

      def respond_to_missing?(_method_name, _include_private = false)
        true
      end

      def on_node(node)
        # Ignore, too noisy
      end

      def after_node(node)
        # Ignore, too noisy
      end
    end
  end
end
