# frozen_string_literal: true

module LiquidLanguageServer
  class Application
    def start
      router = LiquidLanguageServer::Router.new
      server = LiquidLanguageServer::Server.new(router: router)
      server.listen
    end
  end
end
