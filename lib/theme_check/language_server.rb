# frozen_string_literal: true
require_relative "language_server/handler"
require_relative "language_server/server"
require_relative "language_server/tokens"

module ThemeCheck
  module LanguageServer
    def self.start
      Server.new.listen
    end
  end
end
