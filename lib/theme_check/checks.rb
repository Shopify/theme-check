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

    def always_enabled
      self.class.new(reject(&:can_disable?))
    end

    def except_for(disabled_checks)
      still_enabled = reject { |check| disabled_checks.all.include?(check.code_name) }

      self.class.new((always_enabled + still_enabled).uniq)
    end
  end
end
