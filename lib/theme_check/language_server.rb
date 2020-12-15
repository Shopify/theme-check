require_relative "language_server/handler"
require_relative "language_server/server"

module ThemeCheck
  module LanguageServer
    def self.start
      Server.new.listen
    end
  end
end