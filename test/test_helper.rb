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
    # Ported from active_support/testing/stream
    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(IO::NULL)
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
      old_stream.close
    end

    # Ported from active_support/testing/stream
    def capture(stream)
      stream = stream.to_s
      captured_stream = Tempfile.new(stream)
      stream_io = eval("$#{stream}") # # rubocop:disable Security/Eval
      origin_stream = stream_io.dup
      stream_io.reopen(captured_stream)

      yield

      stream_io.rewind
      captured_stream.read
    ensure
      captured_stream.close
      captured_stream.unlink
      stream_io.reopen(origin_stream)
    end

    def parse_liquid(code)
      storage = make_storage("file.liquid" => code)
      ThemeCheck::LiquidFile.new("file.liquid", storage)
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
        path.write(content, mode: 'w+b')
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
      sources = theme.liquid.map { |theme_file| [theme_file.relative_path.to_s, theme_file.rewriter.to_s] }
      Hash[*sources.flatten]
    end

    def assert_offenses(output, offenses)
      # Making sure nothing blows up in the language_server
      offenses.each do |offense|
        assert(offense.start_row)
        assert(offense.start_column)
        assert(offense.end_row)
        assert(offense.end_column)
      end

      assert_equal(
        output.chomp,
        offenses
          .sort_by { |o| [o.location, o.message].join(' ') }
          .join("\n")
      )
    end

    def assert_offenses_with_range(output, offenses)
      # Making sure nothing blows up in the language_server
      offenses.each do |offense|
        assert(offense.start_row)
        assert(offense.start_column)
        assert(offense.end_row)
        assert(offense.end_column)
      end

      assert_equal(
        output.chomp,
        offenses
          .sort_by { |o| [o.location_range, o.message].join(' ') }
          .map(&:to_s_range)
          .join("\n")
      )
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

    class MockMessenger < ThemeCheck::LanguageServer::Messenger
      attr_accessor :logs, :sent_messages
      attr_writer :supports_work_done_progress

      def initialize
        @logs = []
        @sent_messages = []
        @supports_work_done_progress = false
        @queue = Queue.new
      end

      def read_message
        @queue.pop
      ensure
        raise ThemeCheck::LanguageServer::DoneStreaming if @queue.closed?
      end

      def send_message(message_body)
        @sent_messages << JSON.parse(message_body, symbolize_names: true)
      end

      def log(s)
        logs << s
      end

      def close_input
        @queue.close
      end

      def close_output; end

      def send_mock_message(message)
        @queue << message
      end
    end
  end
end
