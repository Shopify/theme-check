# frozen_string_literal: true

module ThemeCheck
  module Tags
    class Base < Liquid::Tag
      SYNTAX = /(#{Liquid::QuotedFragment}+)(\s*(#{Liquid::QuotedFragment}+))?/o
      # this is Liquid::TagAttributes with the beginnig changed from \w+ to [\w-] to allow for
      # attributes like html-id: 10, which was identified as id: 10, but should be html-id: 10.
      # In other words - allow hyphens in key names.
      TAG_ATTRIBUTES = /([\w-]+)\s*:\s*((?-mix:(?-mix:"[^"]*"|'[^']*')|(?:[^\s,|'"]|(?-mix:"[^"]*"|'[^']*'))+))/
      BACKWARDS_COMPATIBILITY_KEYS = %w[method].freeze

      def initialize(tag_name, markup, parse_context)
        super
        parse_markup(tag_name, markup)
      end

      protected

      def parse_markup(tag_name, markup)
        @remaining_markup = markup

        parse_main_value(tag_name, markup)
        parse_attributes(@remaining_markup)
      end

      def parse_main_value(tag_name, markup)
        raise Liquid::SyntaxError, "Invalid syntax for #{tag_name} tag" unless markup =~ syntax

        @main_value = Regexp.last_match(1)
        @remaining_markup = markup[Regexp.last_match.end(1)..-1] if @main_value

        @value_expr = @main_value ? Liquid::Expression.parse(@main_value) : nil
      end

      def parse_attributes(markup)
        @attributes_expr = {}

        markup.scan(TAG_ATTRIBUTES) do |key, value|
          unless well_formed_object_access?(value)
            raise Liquid::SyntaxError,
              'Invalid syntax for function tag, no spaces allowed when accessing array or hash.'
          end

          @attributes_expr[key] = Liquid::Expression.parse(value)
        end
      end

      def well_formed_object_access?(representation)
        return false if /\[\z/.match?(representation.to_s)

        true
      end

      def syntax
        SYNTAX
      end
    end
    # Copied tags parsing code from storefront-renderer

    class Section < Liquid::Tag
      SYNTAX = /\A\s*(?<section_name>#{Liquid::QuotedString})\s*\z/o

      attr_reader :section_name

      def initialize(tag_name, markup, options)
        super

        match = markup.match(SYNTAX)
        raise(
          Liquid::SyntaxError,
          "Error in tag 'section' - Valid syntax: section '[type]'",
        ) unless match
        @section_name = match[:section_name].tr(%('"), '')
        @section_name.chomp!(".liquid") if @section_name.end_with?(".liquid")
      end
    end

    class Sections < Liquid::Tag
      SYNTAX = /\A\s*(?<sections_name>#{Liquid::QuotedString})\s*\z/o

      attr_reader :sections_name

      def initialize(tag_name, markup, options)
        super

        match = markup.match(SYNTAX)
        raise(
          Liquid::SyntaxError,
          "Error in tag 'sections' - Valid syntax: sections '[type]'",
        ) unless match
        @sections_name = match[:sections_name].tr(%('"), '')
        @sections_name.chomp!(".liquid") if @sections_name.end_with?(".liquid")
      end
    end

    class Form < Liquid::Block
      TAG_ATTRIBUTES = /([\w\-]+)\s*:\s*(#{Liquid::QuotedFragment})/o
      # Matches forms with arguments:
      #  'type', object
      #  'type', object, key: value, ...
      #  'type', key: value, ...
      #
      # old format: form product
      # new format: form "product", product, id: "newID", class: "custom-class", data-example: "100"
      FORM_FORMAT = %r{
      (?<type>#{Liquid::QuotedFragment})
      (?:\s*,\s*(?<variable_name>#{Liquid::VariableSignature}+)(?!:))?
        (?<attributes>(?:\s*,\s*(?:#{TAG_ATTRIBUTES}))*)\s*\Z
        }xo

        attr_reader :type_expr, :variable_name_expr, :tag_attributes

      def initialize(tag_name, markup, options)
        super
        @match = FORM_FORMAT.match(markup)
        raise Liquid::SyntaxError, "in 'form' - Valid syntax: form 'type'[, object]" unless @match
        @type_expr = parse_expression(@match[:type])
        @variable_name_expr = parse_expression(@match[:variable_name])
        tag_attributes = @match[:attributes].scan(TAG_ATTRIBUTES)
        tag_attributes.each do |kv_pair|
          kv_pair[1] = parse_expression(kv_pair[1])
        end
        @tag_attributes = tag_attributes
      end

      class ParseTreeVisitor < Liquid::ParseTreeVisitor
        def children
          super + [@node.type_expr, @node.variable_name_expr] + @node.tag_attributes
        end
      end
    end

    class Paginate < Liquid::Block
      SYNTAX = /(?<liquid_variable_name>#{Liquid::QuotedFragment})\s*((?<by>by)\s*(?<page_size>#{Liquid::QuotedFragment}))?/

      attr_reader :page_size

      def initialize(tag_name, markup, options)
        super
        if (matches = markup.match(SYNTAX))
          @liquid_variable_name = matches[:liquid_variable_name]
          @page_size = parse_expression(matches[:page_size])
          @window_size = nil # determines how many pagination links are shown

          @liquid_variable_count_expr = parse_expression("#{@liquid_variable_name}_count")

          var_parts = @liquid_variable_name.rpartition('.')
          @source_drop_expr = parse_expression(var_parts[0].empty? ? var_parts.last : var_parts.first)
          @method_name = var_parts.last.to_sym

          markup.scan(Liquid::TagAttributes) do |key, value|
            case key
            when 'window_size'
              @window_size = value.to_i
            end
          end
        else
          raise(Liquid::SyntaxError, "in tag 'paginate' - Valid syntax: paginate [collection] by number")
        end
      end

      class ParseTreeVisitor < Liquid::ParseTreeVisitor
        def children
          super + [@node.page_size]
        end
      end
    end

    class Layout < Liquid::Tag
      SYNTAX = /(?<layout>#{Liquid::QuotedFragment})/

      NO_LAYOUT_KEYS = %w(false nil none).freeze

      attr_reader :layout_expr

      def initialize(tag_name, markup, tokens)
        super
        match = markup.match(SYNTAX)
        raise(
          Liquid::SyntaxError,
          "in 'layout' - Valid syntax: layout (none|[layout_name])",
        ) unless match
        layout_markup = match[:layout]
        @layout_expr = if NO_LAYOUT_KEYS.include?(layout_markup.downcase)
                         false
                       else
                         parse_expression(layout_markup)
                       end
      end

      class ParseTreeVisitor < Liquid::ParseTreeVisitor
        def children
          [@node.layout_expr]
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
                         ## variables passed into the tag (e.g. {% render "snippet", var1: value1, var2: value2 %}
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

    class Style < Liquid::Block; end

    class Background < Base
      PARTIAL_SYNTAX = /(#{Liquid::VariableSignature}+)\s*=\s*(.*)\s*/om
      CLOSE_TAG_SYNTAX = /\A(.*)(?-mix:\{%-?)\s*(\w+)\s*(.*)?(?-mix:%\})\z/m # based on Liquid::Raw::FullTokenPossiblyInvalid

      def initialize(tag_name, markup, options)
        if markup =~ PARTIAL_SYNTAX
          super
          @to = Regexp.last_match(1)
          @partial_syntax = true

          after_assign_markup = Regexp.last_match(2).split('|')
          parse_markup(tag_name, after_assign_markup.shift)
          after_assign_markup.unshift(@to)
          @from = Liquid::Variable.new(after_assign_markup.join('|'), options)
        else
          @partial_syntax = false
          parse_markup(tag_name, markup)
          super
        end
      end

      def parse(tokens)
        return super if @partial_syntax

        @body = +''
        while (token = tokens.send(:shift))
          if token =~ CLOSE_TAG_SYNTAX && block_delimiter == Regexp.last_match(2)
            @body << Regexp.last_match(1) if Regexp.last_match(1) != ''
            return
          end
          @body << token unless token.empty?
        end

        raise Liquid::SyntaxError, parse_context.locale.t('errors.syntax.tag_never_closed', block_name:)
      end

      def block_name
        @tag_name
      end

      def block_delimiter
        @block_delimiter = "end#{block_name}"
      end

      def parse_main_value(tag_name, markup)
        raise Liquid::SyntaxError, "Invalid syntax for #{tag_name} tag" unless markup =~ syntax

        @main_value = Regexp.last_match(1)
        @value_expr = @main_value ? Liquid::Expression.parse(@main_value) : nil
      end
    end

    class Function < Liquid::Tag; end

    class Log < Liquid::Tag; end

    class Schema < Liquid::Raw; end

    class Javascript < Liquid::Raw; end

    class Stylesheet < Liquid::Raw; end

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
        register_tag('form', Form)
        register_tag('layout', Layout)
        register_tag('render', Render)
        register_tag('paginate', Paginate)
        register_tag('section', Section)
        register_tag('sections', Sections)
        register_tag('style', Style)
        register_tag('log', Log)
        register_tag('background', Background)
        register_tag('function', Function)
        register_tag('schema', Schema)
        register_tag('javascript', Javascript)
        register_tag('stylesheet', Stylesheet)
      end
    end
    self.register_tags = true
  end

end
