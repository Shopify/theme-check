# frozen_string_literal: true
require 'theme_check/version'

module ThemeCheck
  class ThemeCheckError < StandardError; end

  BUG_POSTAMBLE = <<~EOS
    Theme Check Version: #{VERSION}
    Ruby Version: #{RUBY_VERSION}
    Platform: #{RUBY_PLATFORM}
    Muffin mode: activated

    ------------------------
    Whoops! It looks like you found a bug in Theme Check.
    Please report it at https://github.com/Shopify/theme-check/issues, and include the message above.
    Or cross your fingers real hard, and try again.
  EOS

  def self.bug(message)
    raise ThemeCheckError, message + BUG_POSTAMBLE
  end
end
