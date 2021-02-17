# frozen_string_literal: true

module ThemeCheck
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

  class CompletionEngine
    WORD = /\w+/

    def initialize(storage)
      @storage = storage
      @buffers = {}
    end

    def completions(name, line, col)
      token = find_token(name, line, col)
      return [] if token.nil?

      if tag_completion?(token, line, col)
        partial = token.content.match(WORD)[0]
        ShopifyLiquid::Tag.labels
          .select { |w| w.starts_with?(partial) }
          .map { |tag| tag_to_completion(tag) }
      elsif object_completion?(token, line, col)
        partial = token.content.match(WORD)[0]
        ShopifyLiquid::Object.labels
          .select { |w| w.starts_with?(partial) }
          .map { |object| object_to_completion(object) }
      else
        []
      end
    end

    def find_token(name, line, col)
      template = @storage.read(name)
      Tokens.new(template).find do |token|
        # it's easier to make a condition for is it out than is it in.
        is_out_of_bounds = (
          line < token.start_line ||
          token.end_line < line ||
          (token.start_line == line && col < token.start_col) ||
          (token.end_line == line && token.end_col < col)
        )

        !is_out_of_bounds
      end
    end

    private

    def cursor_on_first_word?(token, line, col)
      return false unless token.content.match?(WORD)
      word_start = token.content.index(WORD)
      word_end = word_start + token.content.match(WORD)[0].size
      token.start_line == line &&
      (col - token.start_col) >= word_start &&
      (col - token.start_col) <= word_end + 1 # the plus 1 is so we consider the next "space" still in the word
    end

    def tag_completion?(token, line, col)
      token.content.starts_with?(Liquid::TagStart) && cursor_on_first_word?(token, line, col)
    end

    def tag_to_completion(tag)
      {
        label: tag,
        kind: CompletionItemKinds::KEYWORD,
      }
    end

    def object_completion?(token, line, col)
      token.content.match?(/^\{\{\s+\w+/) && cursor_on_first_word?(token, line, col)
    end

    def object_to_completion(tag)
      {
        label: tag,
        kind: CompletionItemKinds::VARIABLE,
      }
    end
  end
end
