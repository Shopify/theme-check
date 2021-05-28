# frozen_string_literal: true
require_relative "language_server/protocol"
require_relative "language_server/constants"
require_relative "language_server/handler"
require_relative "language_server/server"
require_relative "language_server/tokens"
require_relative "language_server/variable_lookup_finder"
require_relative "language_server/completion_helper"
require_relative "language_server/completion_provider"
require_relative "language_server/completion_engine"
require_relative "language_server/document_link_engine"
require_relative "language_server/diagnostics_tracker"

Dir[__dir__ + "/language_server/completion_providers/*.rb"].each do |file|
  require file
end

module ThemeCheck
  module LanguageServer
    def self.start
      Server.new.listen
    end
  end
end
