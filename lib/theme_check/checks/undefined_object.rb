# frozen_string_literal: true
module ThemeCheck
  class UndefinedObject < LiquidCheck
    category :liquid
    doc "https://shopify.dev/docs/themes/liquid/reference/objects"
    severity :error

    class TemplateInfo
      def initialize
        @all_variable_lookups = {}
        @all_assigns = {}
        @all_captures = {}
        @all_forloops = {}
        @all_renders = {}
      end

      attr_reader :all_assigns, :all_captures, :all_forloops

      def add_render(name:, node:)
        @all_renders[name] = node
      end

      def add_variable_lookup(name:, node:)
        line_number = node.parent.line_number
        key = [name, line_number]
        @all_variable_lookups[key] = node
      end

      def all_variables
        all_assigns.keys + all_captures.keys + all_forloops.keys
      end

      def each_snippet
        @all_renders.each do |(name, info)|
          yield [name, info]
        end
      end

      def each_variable_lookup(unique_keys = false)
        seen = Set.new
        @all_variable_lookups.each do |(key, info)|
          name, _line_number = key

          next if unique_keys && seen.include?(name)
          seen << name

          yield [key, info]
        end
      end
    end

    def initialize
      @files = {}
    end

    def on_document(node)
      @files[node.template.name] = TemplateInfo.new
    end

    def on_assign(node)
      @files[node.template.name].all_assigns[node.value.to] = node
    end

    def on_capture(node)
      @files[node.template.name].all_captures[node.value.instance_variable_get('@to')] = node
    end

    def on_for(node)
      @files[node.template.name].all_forloops[node.value.variable_name] = node
    end

    def on_include(_node)
      # NOOP: we purposely do nothing on `include` since it is deprecated
      #   https://shopify.dev/docs/themes/liquid/reference/tags/deprecated-tags#include
    end

    def on_render(node)
      return unless node.value.template_name_expr.is_a?(String)

      snippet_name = "snippets/#{node.value.template_name_expr}"
      @files[node.template.name].add_render(
        name: snippet_name,
        node: node,
      )
    end

    def on_variable_lookup(node)
      @files[node.template.name].add_variable_lookup(
        name: node.value.name,
        node: node,
      )
    end

    def on_end
      all_global_objects = ThemeCheck::ShopifyLiquid::Object.labels
      all_global_objects.freeze

      shopify_plus_objects = ThemeCheck::ShopifyLiquid::Object.plus_labels
      shopify_plus_objects.freeze

      each_template do |(name, info)|
        if 'templates/customers/reset_password' == name
          # NOTE: `email` is exceptionally exposed as a theme object in
          #       the customers' reset password template
          check_object(info, all_global_objects + ['email'])
        elsif 'layout/checkout' == name
          # NOTE: Shopify Plus has exceptionally exposed objects in
          #       the checkout template
          # https://shopify.dev/docs/themes/theme-templates/checkout-liquid#optional-objects
          check_object(info, all_global_objects + shopify_plus_objects)
        else
          check_object(info, all_global_objects)
        end
      end
    end

    def each_template
      @files.each do |(name, info)|
        next if name.starts_with?('snippets/')
        yield [name, info]
      end
    end
    private :each_template

    def check_object(info, all_global_objects, render_node = nil)
      check_undefined(info, all_global_objects, render_node)

      info.each_snippet do |(snippet_name, node)|
        snippet_info = @files[snippet_name]
        next unless snippet_info # NOTE: undefined snippet

        snippet_variables = node.value.attributes.keys +
          Array[node.value.instance_variable_get("@alias_name")]
        check_object(snippet_info, all_global_objects + snippet_variables, node)
      end
    end
    private :check_object

    def check_undefined(info, all_global_objects, render_node)
      all_variables = info.all_variables

      info.each_variable_lookup(!!render_node) do |(key, node)|
        name, _line_number = key
        next if all_variables.include?(name)
        next if all_global_objects.include?(name)

        node = node.parent
        node = node.parent if %i(condition variable_lookup).include?(node.type_name)

        if render_node
          add_offense("Missing argument `#{name}`", node: render_node)
        else
          add_offense("Undefined object `#{name}`", node: node)
        end
      end
    end
    private :check_undefined
  end
end
