# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class FilterCompletionProvider < CompletionProvider
      NAMED_FILTER = /#{Liquid::FilterSeparator}\s*(\w+)/o
      FILTER_SEPARATOR_INCLUDING_SPACES = /\s*#{Liquid::FilterSeparator}/
      INPUT_TYPE_VARIABLE = 'variable'

      def completions(context)
        content = context.content
        cursor = context.cursor

        return [] if content.nil?
        return [] unless can_complete?(content, cursor)

        context = context_with_cursor_before_potential_filter_separator(context)
        available_labels_for(determine_input_type(context))
          .select { |w| w.start_with?(partial(content, cursor)) }
          .map { |filter| filter_to_completion(filter) }
      end

      def can_complete?(content, cursor)
        content.match?(Liquid::FilterSeparator) && (
          cursor_on_start_content?(content, cursor, Liquid::FilterSeparator) ||
          cursor_on_filter?(content, cursor)
        )
      end

      private

      def context_with_cursor_before_potential_filter_separator(context)
        content = context.content
        diff = content.index(FILTER_SEPARATOR_INCLUDING_SPACES) - content.size

        return context unless content.scan(FILTER_SEPARATOR_INCLUDING_SPACES).size == 1

        context.clone_and_overwrite(col: context.col + diff)
      end

      def determine_input_type(context)
        variable_lookup = VariableLookupFinder.lookup(context)

        if variable_lookup
          object, property = VariableLookupTraverser.lookup_object_and_property(variable_lookup)
          return property.return_type if property
          return object.name if object
        end
      end

      def available_labels_for(input_type)
        filters = ShopifyLiquid::SourceIndex.filters
          .filter_map do |filter|
          filter.name if input_type.nil? ||
            filter.input_type == input_type
        end
        return available_labels_for(nil) if filters.empty?
        return filters if input_type == INPUT_TYPE_VARIABLE

        filters + available_labels_for(INPUT_TYPE_VARIABLE)
      end

      def cursor_on_filter?(content, cursor)
        return false unless content.match?(NAMED_FILTER)

        matches(content, NAMED_FILTER).any? do |match|
          match.begin(1) <= cursor && cursor < match.end(1) + 1 # including next character
        end
      end

      def partial(content, cursor)
        return '' unless content.match?(NAMED_FILTER)

        partial_match = matches(content, NAMED_FILTER).find do |match|
          match.begin(1) <= cursor && cursor < match.end(1) + 1 # including next character
        end
        return '' if partial_match.nil?

        partial_match[1]
      end

      def filter_to_completion(filter)
        content = ShopifyLiquid::Documentation.filter_doc(filter)

        {
          label: filter,
          kind: CompletionItemKinds::FUNCTION,
          **doc_hash(content),
        }
      end
    end
  end
end
