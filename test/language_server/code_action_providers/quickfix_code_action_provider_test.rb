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
        assert(DiagnosticsTracker.method_defined?("single_file_offenses"))
        assert(Offense.method_defined?("message"))
        assert(Offense.method_defined?("to_diagnostic"))
        assert(Offense.method_defined?("correctable?"))
        assert(Offense.method_defined?("range"))
      end
    end
  end
end
