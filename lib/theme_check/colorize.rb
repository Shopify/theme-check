# frozen_string_literal: true

module ThemeCheck
  module Colorize
    def colorize(str, color_code)
      "\e[#{color_code}m#{str}\e[0m"
    end

    def red(str)
      colorize(str, 31)
    end

    def green(str)
      colorize(str, 32)
    end

    def yellow(str)
      colorize(str, 33)
    end

    def blue(str)
      colorize(str, 34)
    end

    def pink(str)
      colorize(str, 35)
    end

    def light_blue(str)
      colorize(str, 36)
    end
  end
end
