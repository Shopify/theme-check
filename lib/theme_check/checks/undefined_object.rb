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
      end

      attr_reader :all_variable_lookups, :all_assigns, :all_captures, :all_forloops
      def all
        all_assigns.keys + all_captures.keys + all_forloops.keys
      end
    end

    def initialize
      @templates = {}
      @used_snippets = {}
    end

    def on_document(node)
      @templates[node.template.name] = TemplateInfo.new
    end

    def on_assign(node)
      @templates[node.template.name].all_assigns[node.value.to] = node
    end

    def on_capture(node)
      @templates[node.template.name].all_captures[node.value.instance_variable_get('@to')] = node
    end

    def on_for(node)
      @templates[node.template.name].all_forloops[node.value.variable_name] = node
    end

    def on_include(node)
      return unless node.value.template_name_expr.is_a?(String)
      name = "snippets/#{node.value.template_name_expr}"
      @used_snippets[name] ||= Set.new
      @used_snippets[name] << node.template.name
    end

    def on_variable_lookup(node)
      @templates[node.template.name].all_variable_lookups[node.value.name] = node
    end

    def on_end
      foster_snippets = theme.snippets
        .reject { |t| @used_snippets.include?(t.name) }
        .map(&:name)

      @templates.each do |(template_name, info)|
        next if foster_snippets.include?(template_name)
        if (all_including_templates = @used_snippets[template_name])
          all_including_templates.each do |including_template|
            including_template_info = @templates[including_template]
            check_object(info.all_variable_lookups, including_template_info.all)
          end
        else
          all = info.all
          all += ['email'] if 'templates/customers/reset_password' == template_name
          check_object(info.all_variable_lookups, all)
        end
      end
    end

    def check_object(variable_lookups, all)
      variable_lookups.each do |(name, node)|
        next if all.include?(name)
        next if ThemeCheck::ShopifyLiquid::Object.labels.include?(name)

        parent = node.parent
        parent = parent.parent if :variable_lookup == parent.type_name
        add_offense("Undefined object `#{name}`", node: parent)
      end
    end
    private :check_object
  end
end
