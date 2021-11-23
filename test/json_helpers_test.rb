# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class JsonHelpersTest < Minitest::Test
    include JsonHelpers
    def test_pretty_json
      test_obj = {
        "a" => {
          "b" => "c",
        },
        "d" => [
          "e",
          "f",
          "g",
        ],
        "h" => {
          "i" => "j",
          "k" => [
            "l",
            "m",
            "n",
          ],
        },
      }

      assert_equal(<<~JSON, pretty_json(test_obj, 0))

        {
          "a": {
            "b": "c"
          },
          "d": [
            "e",
            "f",
            "g"
          ],
          "h": {
            "i": "j",
            "k": [
              "l",
              "m",
              "n"
            ]
          }
        }
      JSON
    end
  end
end
