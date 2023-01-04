# frozen_string_literal: true
module ThemeCheck
  # Reports errors when invalid tags are used in a Theme App
  # Extension block
  class AppBlockValidTags < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    # Don't allow this check to be disabled with a comment,
    # since we need to be able to enforce this server-side
    can_disable false

    OFFENSE_MSG = "Theme app extension blocks cannot contain %s tags"

    def on_javascript(node)
      add_offense(OFFENSE_MSG % 'javascript', node: node)
    end

    def on_stylesheet(node)
      add_offense(OFFENSE_MSG % 'stylesheet', node: node)
    end

    def on_include(node)
      add_offense(OFFENSE_MSG % 'include', node: node)
    end

    def on_layout(node)
      add_offense(OFFENSE_MSG % 'layout', node: node)
    end

    def on_section(node)
      add_offense(OFFENSE_MSG % 'section', node: node)
    end

    def on_sections(node)
      add_offense(OFFENSE_MSG % 'sections', node: node)
    end
  end
end
