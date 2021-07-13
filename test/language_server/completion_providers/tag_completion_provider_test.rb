# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class TagCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = TagCompletionProvider.new
      end

      def test_can_complete?
        assert_can_complete(@provider, "{% ")
        assert_can_complete(@provider, "{%  ")
        assert_can_complete(@provider, "{% rend")
        assert_can_complete(@provider, "{% rend")
        assert_can_complete(@provider, "{% rend %}", -3)

        refute_can_complete(@provider, "{{  ")
        refute_can_complete(@provider, "{% if foo")
      end

      def test_completions
        assert_can_complete_with(@provider, "{% rend", "render")
        assert_can_complete_with(@provider, "{% comm", "comment")
      end

      def test_complete_end_blocks
        # the end* are not suggested unless you type end
        refute_can_complete_with(@provider, "{% ", "endcomment")
        refute_can_complete_with(@provider, "{% en", "endcomment")

        # the end* are suggested if end is part of your tag
        assert_can_complete_with(@provider, "{% end", "endcomment")
        assert_can_complete_with(@provider, "{% endcomm", "endcomment")
      end
    end
  end
end
