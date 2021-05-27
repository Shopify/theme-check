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

      Timeout.timeout(CHECK_METHOD_TIMEOUT) do
        check.send(method, *args)
      end
    rescue Liquid::Error
      # Pass-through Liquid errors
      raise
    rescue => e
      node = args.first
      template = node.respond_to?(:template) ? node.template.relative_path : "?"
      markup = node.respond_to?(:markup) ? node.markup : ""
      node_class = node.respond_to?(:value) ? node.value.class : "?"

      ThemeCheck.bug(<<~EOS)
        Exception while running `#{check.code_name}##{method}`:
        ```
        #{e.class}: #{e.message}
          #{e.backtrace.join("\n  ")}
        ```

        Template: `#{template}`
        Node: `#{node_class}`
        Markup:
        ```
        #{markup}
        ```
        Check options: `#{check.options.pretty_inspect}`
      EOS
    end
  end
end
