# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class HtmlElementCompletionProvider < CompletionProvider
      def completions(token, cursor)
        content = token.content
        return [] unless (name = html_element_name_at_cursor(content, cursor))
        Docsets::Html.names
          .select { |w| w.start_with?(name || '') }
          .map { |label| name_to_completion(label) }
      end

      def html_element_name_at_cursor(content, cursor)
        if (match = /^<(?<name>[a-z][a-z0-9\-:]*)?$/i.match(content.slice(0, cursor)))
          match[:name] || ''
        end
      end

      private

      def name_to_completion(name)
        {
          label: name,
          kind: CompletionItemKinds::PROPERTY,
          documentation: docs_for_name(name),
        }
      end

      def docs_for_name(name)
        {
          kind: 'markdown',
          value: markdown_for_name(name),
        }
      end

      def markdown_for_name(name)
        Docsets::Html.element_docs(name)
      end
    end
  end
end
