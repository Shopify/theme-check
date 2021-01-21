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

    def except_disabled(disabled_checks)
      self.class.new(reject { |check| disabled_checks.all.include?(check.code_name) })
    end
  end
end
