# frozen_string_literal: true
module ThemeCheck
  class MissingEnableComment < LiquidCheck
    severity :error
    doc docs_url(__FILE__)

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
      checks_missing_end_index = @disabled_checks.checks_missing_end_index
      return if checks_missing_end_index.empty?

      message = if checks_missing_end_index.any? { |name| name == :all }
        "All checks were"
      else
        checks_missing_end_index.join(', ') + " " + (checks_missing_end_index.size == 1 ? "was" : "were")
      end

      add_offense("#{message} disabled but not re-enabled with theme-check-enable", node: node) do
        script = node.source.to_enum(:scan, /(?<comment_open>{% comment %}theme-check-disable)(?<checks>.*?)(?<comment_close>{% endcomment %})(?<enclosed>[^\n]*\n[^\n]*\n)/m).map { Regexp.last_match }[-1]
        next if script.nil?
        node.source.insert(script.end(:enclosed), "{% comment %}theme-check-enable#{checks_missing_end_index.include?(:all) ? "" : " #{checks_missing_end_index.join(', ')}"}{% endcomment %}\n")
      end
    end
  end
end
