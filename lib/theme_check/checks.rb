# frozen_string_literal: true
module ThemeCheck
  class Checks < Array
    def call(method, *args)
      each do |check|
        if check.respond_to?(method) && !check.ignored?
          check.send(method, *args)
        end
      end
    end

    # Return a collection of checks except for disabled checks represented
    # as a DisabledChecks instance — or `nil`, if all checks are meant to be disabled.
    # Still returns checks marked as `always_enabled!`
    def except_disabled(disabled_checks = nil)
      always_enabled = select(&:always_enabled?)

      return self.class.new(always_enabled) if disabled_checks.nil?

      still_enabled = reject { |check| disabled_checks.all.include?(check.code_name) }

      self.class.new((always_enabled + still_enabled).uniq)
    end
  end
end
