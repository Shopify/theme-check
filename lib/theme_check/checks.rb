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
  end
end
