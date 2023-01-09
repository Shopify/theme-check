# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class Documentation
      class MarkdownTemplate
        MARKDOWN_RELATIVE_LINK = %r{(\[([^\[]+)\]\((/[^\)]+)\))*}

        def render(entry)
          [
            title(entry),
            body(entry),
          ].reject(&:empty?).join("\n")
        end

        private

        def title(entry)
          "### [#{entry.name}](#{entry.shopify_dev_url})"
        end

        def body(entry)
          [entry.deprecation_reason, entry.summary, entry.description]
            .reject(&:nil?)
            .reject(&:empty?)
            .join(horizontal_rule)
            .tap { |body| break(patch_urls!(body)) }
        end

        def horizontal_rule
          "\n\n---\n\n"
        end

        def patch_urls!(body)
          body.gsub(MARKDOWN_RELATIVE_LINK) do |original_link|
            match = Regexp.last_match

            text = match[2]
            path = match[3]

            if text && path
              "[#{text}](https://shopify.dev#{path})"
            else
              original_link
            end
          end
        end
      end
    end
  end
end
