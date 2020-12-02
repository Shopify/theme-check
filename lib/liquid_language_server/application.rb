# frozen_string_literal: true

module LiquidLanguageServer
  class Application
    def start
      server = LiquidLanguageServer::Server.new
      LiquidLanguageServer::IO.new(server)
    end
  end
end
