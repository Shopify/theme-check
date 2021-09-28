# frozen_string_literal: true
require_relative "language_server/protocol"
require_relative "language_server/constants"
require_relative "language_server/channel"
require_relative "language_server/messenger"
require_relative "language_server/io_messenger"
require_relative "language_server/bridge"
require_relative "language_server/uri_helper"
require_relative "language_server/server"
require_relative "language_server/tokens"
require_relative "language_server/variable_lookup_finder"
require_relative "language_server/diagnostics_tracker"
require_relative "language_server/diagnostics_engine"

require_relative "language_server/completion_helper"
require_relative "language_server/completion_provider"
require_relative "language_server/completion_engine"
Dir[__dir__ + "/language_server/completion_providers/*.rb"].each do |file|
  require file
end

require_relative "language_server/document_link_provider"
require_relative "language_server/document_link_engine"
Dir[__dir__ + "/language_server/document_link_providers/*.rb"].each do |file|
  require file
end

require_relative "language_server/handler"

module ThemeCheck
  module LanguageServer
    def self.start
      Server.new(messenger: IOMessenger.new).listen
    end
  end
end
