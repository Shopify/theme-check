# frozen_string_literal: true

module LiquidLanguageServer
  class Application
    def start
      router = LiquidLanguageServer::Router.new
      LiquidLanguageServer::Server.new(router)
    end
  end
end
