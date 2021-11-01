# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class QuickfixCodeActionProviderTest < Minitest::Test
      # This class is really hard to test since it depends on a lot.
      # However, it doesn't do a lot. So instead of testing the whole
      # thing, we'll make sure that the methods we call exist and
      # depend on their unit test to do their job correctly.
      def test_dependencies_have_expected_methods
        assert(DiagnosticsManager.method_defined?("diagnostics"))
        assert(Diagnostic.method_defined?("message"))
        assert(Diagnostic.method_defined?("correctable?"))
        assert(Diagnostic.method_defined?("offense"))
        assert(Diagnostic.method_defined?("to_h"))
        assert(Offense.method_defined?("range"))
      end
    end
  end
end
