# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      module TolerantParser
        class Template
          class << self
            def parse(content)
              ##
              # The tolerant parser relies on a tolerant custom parse
              # context to creates a new 'Template' object, even when
              # a block is not closed.
              Liquid::Template.parse(content, custom_parse_context)
            end

            private

            def custom_parse_context
              ParseContext.new
            end
          end
        end

        class ParseContext < Liquid::ParseContext
          def new_block_body
            BlockBody.new
          end
        end

        class BlockBody < Liquid::BlockBody
          ##
          # The tags are statically defined and referenced at the
          # 'Liquid::Template', so the TolerantParser just uses the
          # redefined tags at this custom block body. Thus, there's
          # no side-effects between the regular and the tolerant parsers.
          def registered_tags
            Tags.new(super)
          end
        end

        class Tags
          module TolerantBlockBody
            ##
            # This module defines the tolerant parse body that doesn't
            # raise syntax errors when a block is not closed. Thus, the
            # tolerant parser can build the AST for templates with this
            # kind of error, which is quite common in language servers.
            def parse_body(body, tokens)
              super
            rescue StandardError
              false
            end
          end

          class Case < Liquid::Case
            include TolerantBlockBody
          end

          class For < Liquid::For
            include TolerantBlockBody
          end

          class If < Liquid::If
            include TolerantBlockBody
          end

          class TableRow < Liquid::TableRow
            include TolerantBlockBody
          end

          class Unless < Liquid::Unless
            include TolerantBlockBody
          end

          class Paginate < Liquid::Tag
            include TolerantBlockBody
          end

          class Form < Liquid::Tag
            include TolerantBlockBody
          end

          class Style < Liquid::Tag
            include TolerantBlockBody
          end

          class Stylesheet < Liquid::Tag
            include TolerantBlockBody
          end

          def initialize(standard_tags)
            @standard_tags = standard_tags
            @tolerant_tags = {
              'case' => Case,
              'for' => For,
              'form' => Form,
              'if' => If,
              'paginate' => Paginate,
              'style' => Style,
              'stylesheet' => Stylesheet,
              'tablerow' => TableRow,
              'unless' => Unless,
            }
          end

          def [](key)
            @tolerant_tags[key] || @standard_tags[key]
          end
        end
      end
    end
  end
end
