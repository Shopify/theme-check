# frozen_string_literal: true
# Here we define the Language Server Protocol Constants we're using.
# For complete docs, see the following:
# https://microsoft.github.io/language-server-protocol/specifications/specification-current
module ThemeCheck
  module LanguageServer
    module CompletionItemKinds
      TEXT = 1
      METHOD = 2
      FUNCTION = 3
      CONSTRUCTOR = 4
      FIELD = 5
      VARIABLE = 6
      CLASS = 7
      INTERFACE = 8
      MODULE = 9
      PROPERTY = 10
      UNIT = 11
      VALUE = 12
      ENUM = 13
      KEYWORD = 14
      SNIPPET = 15
      COLOR = 16
      FILE = 17
      REFERENCE = 18
      FOLDER = 19
      ENUM_MEMBER = 20
      CONSTANT = 21
      STRUCT = 22
      EVENT = 23
      OPERATOR = 24
      TYPE_PARAMETER = 25
    end

    module TextDocumentSyncKind
      NONE = 0
      FULL = 1
      INCREMENTAL = 2
    end
  end
end
