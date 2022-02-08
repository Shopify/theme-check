# frozen_string_literal: true
require "pp"
require "timeout"

module ThemeCheck
  class Checks < Array
    CHECK_METHOD_TIMEOUT = 5 # sec

    def call(method, *args)
      each do |check|
        call_check_method(check, method, *args)
      end
    end

    def disableable
      @disableable ||= self.class.new(select(&:can_disable?))
    end

    def whole_theme
      @whole_theme ||= self.class.new(select(&:whole_theme?))
    end

    def single_file
      @single_file ||= self.class.new(select(&:single_file?))
    end

    private

    def call_check_method(check, method, *args)
      return unless check.respond_to?(method) && !check.ignored?

      # If you want to use binding.pry in unit tests, define the
      # THEME_CHECK_DEBUG environment variable. e.g.
      #
      #   $ export THEME_CHECK_DEBUG=true
      #   $ bundle exec rake tests:in_memory
      #
      if ENV['THEME_CHECK_DEBUG']
        check.send(method, *args)
      else
        Timeout.timeout(CHECK_METHOD_TIMEOUT) do
          check.send(method, *args)
        end
      end
    rescue Liquid::Error, ThemeCheckError
      raise
    rescue => e
      node = args.first
      theme_file = node.respond_to?(:theme_file) ? node.theme_file.relative_path : "?"
      markup = node.respond_to?(:markup) ? node.markup : ""
      node_class = node.respond_to?(:value) ? node.value.class : "?"
      line_number = node.respond_to?(:line_number) ? node.line_number : "?"

      ThemeCheck.bug(<<~EOS)
        Exception while running `#{check.code_name}##{method}`:
        ```
        #{e.class}: #{e.message}
          #{e.backtrace.join("\n  ")}
        ```

        Theme File: `#{theme_file}`
        Node: `#{node_class}`
        Markup:
        ```
        #{markup}
        ```
        Line number: #{line_number}
        Check options: `#{check.options.pretty_inspect}`
      EOS
    end
  end
end
