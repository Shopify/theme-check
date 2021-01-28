# frozen_string_literal: true
module ThemeCheck
  class MissingEnableComment < LiquidCheck
    severity :error

    # Don't allow this check to be disabled with a comment,
    # as we need to be able to check for disabled checks.
    can_disable false

    def on_document(_node)
      @disabled_checks = DisabledChecks.new
    end

    def on_comment(node)
      @disabled_checks.update(node)
    end

    def after_document(node)
      return if @disabled_checks.full_document_disabled?
      return unless @disabled_checks.any?

      message = if @disabled_checks.all_disabled?
        "All checks were"
      else
        @disabled_checks.all.join(', ') + " " + (@disabled_checks.all.size == 1 ? "was" : "were")
      end

      add_offense("#{message} disabled but not re-enabled with theme-check-enable", node: node)
    end
  end
end
