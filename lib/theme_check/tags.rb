# frozen_string_literal: true

module ThemeCheck
  module Tags
    # Copied tags parsing code from storefront-renderer

    class Translate < Liquid::Tag
      SYNTAX = /\s*(#{::Liquid::QuotedString})\s*/ # careful with newlines

      attr_reader :original, :params

      def initialize(tag_name, markup, parse_context)
        super
        raise ::Liquid::SyntaxError.new('Syntax Error in "t" - Valid syntax: {% t "text string" %}'), 'Syntax Error' unless markup =~ SYNTAX

        @original = parse_expression(Regexp.last_match[1])
        raise ::Liquid::SyntaxError.new('Syntax Error in "t" - Valid syntax: {% t "text string" %}'), 'Syntax Error' unless original.is_a?(String)

        @original.strip!
        @params = {}

        after_markup = markup.strip.delete_prefix(Regexp.last_match[1])
        after_markup.scan(Liquid::TagAttributes) do |key, value|
          @params[key.to_sym] = parse_expression(value)
        end
      end

      def format_variables
        original.scan(/%{.+?}/).map { |s| s[2..-2].strip }.sort.uniq
      end

      def params_keys
        @params.keys.map(&:to_s).sort.uniq
      end

      def params_variables
        @params.values
      end

      class ParseTreeVisitor < Liquid::ParseTreeVisitor
        def children
          super + @node.params_variables
        end
      end
    end

    class Paginate < Liquid::Block
      SYNTAX = /\s*(#{Liquid::QuotedFragment})(\s+by\s+(#{Liquid::QuotedFragment}))?/

      attr_reader :collection_name, :per_page

      def initialize(tag_name, markup, _options)
        super

        raise ::Liquid::SyntaxError.new("Syntax Error in 'paginate' - Valid syntax: paginate <collection> by <number>"), 'Syntax Error' unless markup =~ SYNTAX

        @collection_name = Regexp.last_match[1]
        @per_page = parse_expression(Regexp.last_match[3]) if Regexp.last_match[2]
      end

      class ParseTreeVisitor < Liquid::ParseTreeVisitor
        def children
          (super + [@node.collection_name, @node.per_page]).compact
        end
      end
    end

    class Render < Liquid::Tag
      SYNTAX = %r{
        (
          ## for {% render "snippet" %}
          #{Liquid::QuotedString}+ |
          ## for {% render block %}
          ## We require the variable # segment to be at the beginning of the
          ## string (with \A). This is to prevent code like {% render !foo! %}
          ## from parsing
          \A#{Liquid::VariableSegment}+
        )
        ## for {% render "snippet" with product as p %}
        ## or {% render "snippet" for products p %}
        (\s+(with|#{Liquid::Render::FOR})\s+(#{Liquid::QuotedFragment}+))?
        (\s+(?:as)\s+(#{Liquid::VariableSegment}+))?
        ## variables passed into the tag (e.g. {% render "snippet", var1: value1, var2: value2 %})
        ## are not matched by this regex and are handled by Liquid::Render.initialize
      }xo

      disable_tags "include"

      attr_reader :template_name_expr, :variable_name_expr, :attributes

      def initialize(tag_name, markup, options)
        super

        raise Liquid::SyntaxError, options[:locale].t("errors.syntax.render") unless markup =~ SYNTAX

        template_name = Regexp.last_match(1)
        with_or_for = Regexp.last_match(3)
        variable_name = Regexp.last_match(4)

        @alias_name = Regexp.last_match(6)
        @variable_name_expr = variable_name ? parse_expression(variable_name) : nil
        @template_name_expr = parse_expression(template_name)
        @for = (with_or_for == Liquid::Render::FOR)

        @attributes = {}
        markup.scan(Liquid::TagAttributes) do |key, value|
          @attributes[key] = parse_expression(value)
        end
      end

      class ParseTreeVisitor < Liquid::ParseTreeVisitor
        def children
          [
            @node.template_name_expr,
            @node.variable_name_expr,
          ] + @node.attributes.values
        end
      end
    end

    class << self
      attr_writer :register_tags

      def register_tags?
        @register_tags
      end

      def register_tag(name, klass)
        Liquid::Template.register_tag(name, klass)
      end

      def register_tags!
        return if !register_tags? || (defined?(@registered_tags) && @registered_tags)
        @registered_tags = true
        register_tag('render', Render)
        register_tag('paginate', Paginate)
        register_tag('t', Translate)
      end
    end
    self.register_tags = true
  end
end
