# frozen_string_literal: true

module LiquidLanguageServer
  class Application
    def start
      router = LiquidLanguageServer::Router.new
      server = LiquidLanguageServer::Server.new(router)
      status_code = server.start
      exit!(status_code)
    end
  end
end
