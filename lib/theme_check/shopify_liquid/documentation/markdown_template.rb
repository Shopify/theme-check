# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class Documentation
      class MarkdownTemplate
        def render(entry)
          [
            title(entry),
            body(entry),
          ].reject(&:empty?).join("\n")
        end

        private

        def title(entry)
          "### #{entry.name}"
        end

        def body(entry)
          [entry.summary, entry.description]
            .reject(&:nil?)
            .reject(&:empty?)
            .join(horizontal_rule)
        end

        def horizontal_rule
          "\n\n--\n\n"
        end
      end
    end
  end
end
