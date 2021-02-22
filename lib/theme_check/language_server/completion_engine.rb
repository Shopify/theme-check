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
    end

    def completions(name, line, col)
      token = find_token(name, line, col)
      return [] if token.nil?

      cursor = cursor_index(token, line, col)
      if tag_completion?(token, cursor)
        tag_completions(token)
      elsif object_completion?(token, cursor)
        object_completions(token)
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

    def cursor_index(token, line, col)
      relative_line = line - token.start_line
      return col - token.start_col if relative_line == 0
      PositionConverter.from_line_to_column(relative_line, col, token.content)
    end

    def cursor_on_first_word?(token, cursor)
      word = token.content.match(WORD)
      return false if word.nil?
      word_start = word.begin(0)
      word_end = word.end(0)
      word_start <= cursor && cursor <= word_end
    end

    def cursor_on_start_content?(token, cursor, regex)
      token.content.slice(0, cursor).match?(/^#{regex}(?:\s|\n)*$/m)
    end

    def first_word(token)
      return token.content.match(WORD)[0] if token.content.match?(WORD)
    end

    def tag_completion?(token, cursor)
      token.content.starts_with?(Liquid::TagStart) && (
        cursor_on_first_word?(token, cursor) ||
        cursor_on_start_content?(token, cursor, Liquid::TagStart)
      )
    end

    def tag_completions(token)
      partial = first_word(token) || ''
      ShopifyLiquid::Tag.labels
        .select { |w| w.starts_with?(partial) }
        .map { |tag| tag_to_completion(tag) }
    end

    def tag_to_completion(tag)
      {
        label: tag,
        kind: CompletionItemKinds::KEYWORD,
      }
    end

    def object_completion?(token, cursor)
      token.content.match?(Liquid::VariableStart) && (
        cursor_on_first_word?(token, cursor) ||
        cursor_on_start_content?(token, cursor, Liquid::VariableStart)
      )
    end

    def object_completions(token)
      partial = first_word(token) || ''
      ShopifyLiquid::Object.labels
        .select { |w| w.starts_with?(partial) }
        .map { |object| object_to_completion(object) }
    end

    def object_to_completion(tag)
      {
        label: tag,
        kind: CompletionItemKinds::VARIABLE,
      }
    end
  end
end
