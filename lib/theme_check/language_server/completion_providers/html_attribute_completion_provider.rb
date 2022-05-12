# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class HtmlAttributeCompletionProvider < CompletionProvider
      def completions(token, cursor)
        content = token.content
        return [] unless (name = html_attribute_name_at_cursor(content, cursor, token.tag_name))
        Docsets::Html.attributes(token.tag_name)
          .select { |attr| attr["name"].start_with?(name || '') }
          .map { |attr| attribute_to_completion(attr) }
      end

      # token could be
      # - <a i
      # - <a id="" src
      # - " src
      #
      # Ideally, you'd be able to figure out that you're still in a
      def html_attribute_name_at_cursor(contents, cursor, tag_name)
        return nil unless tag_name
        return nil if contents =~ %r{^(#{TAG_START}|#{VARIABLE_START}|</)}
        return nil if contents[cursor - 1] == '='

        # First we look backwards to find our nearest boundary
        word = contents[0...cursor].reverse

        # boundary = one of ", ' or the tag_name
        boundary = /"|'|\b#{tag_name.reverse}\b/.match(word)

        return '' unless boundary

        # `" class="a b c"`
        #             ^ cursor
        #          ^ boundary
        #         ^ word[boundary.end(0)]
        if boundary[0] =~ /"|'/ && word[boundary.end(0)] == '='
          return nil
        end

        # now that we have found our boundary, go forward on spaces
        # until you find something, strip the whitespace
        word[0...boundary.begin(0)].reverse.strip
      end

      private

      def attribute_to_completion(attribute)
        {
          label: attribute["name"],
          kind: CompletionItemKinds::VALUE,
          documentation: attribute["description"],
        }
      end
    end
  end
end
