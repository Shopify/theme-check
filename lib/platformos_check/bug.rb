# frozen_string_literal: true
require 'platformos_check/version'

module PlatformosCheck
  class PlatformosCheckError < StandardError; end

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
    raise PlatformosCheckError, message + BUG_POSTAMBLE
  end
end
