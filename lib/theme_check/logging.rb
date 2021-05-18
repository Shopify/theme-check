# frozen_string_literal: true
require "benchmark"
require "logger"

module ThemeCheck
  extend Colorize

  MAX_TRACE_LOG_SIZE = 10 * 1024 * 1000 # 10MB
  MAX_TRACE_NUM_LOGS = 10

  def self.trace!(filename)
    @trace_logger = Logger.new(filename, MAX_TRACE_NUM_LOGS, MAX_TRACE_LOG_SIZE)
    @trace_logger.level = Logger::DEBUG
  end

  def self.trace?
    defined?(@trace_logger) && !@trace_logger.nil?
  end

  def self.trace(message)
    if block_given?
      return yield unless trace?
      result = nil
      time = Benchmark.measure { result = yield }
      @trace_logger.debug("#{message} in #{format("%.2f", time.real)}ms")
      result
    else
      @trace_logger.debug(message)
    end
  end

  BUG_POSTAMBLE = <<~EOS
    Theme Check Version: #{VERSION}
    Ruby Version: #{RUBY_VERSION}
    Platform: #{RUBY_PLATFORM}
    Muffin mode: activated

    #{blue("------------------------")}
    #{red("WHOOPS! It looks like you found a bug in Theme Check.")}
    Please report it at https://github.com/Shopify/theme-check/issues, and include the message above.
    Or cross your fingers real hard, and try again.
  EOS

  def self.bug(message)
    abort(message + BUG_POSTAMBLE)
  end
end
