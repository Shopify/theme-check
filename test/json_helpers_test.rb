# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class JsonHelpersTest < Minitest::Test
    include JsonHelpers

    def setup
      @test_obj = {
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
    end

    def test_pretty_json
      assert_equal(<<~JSON, pretty_json(@test_obj, start_level: 0))

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

    def test_pretty_json_with_tabs
      assert_equal(<<~JSON, pretty_json(@test_obj, start_level: 1, indent: "\t"))

        \t{
        \t\t"a": {
        \t\t\t"b": "c"
        \t\t},
        \t\t"d": [
        \t\t\t"e",
        \t\t\t"f",
        \t\t\t"g"
        \t\t],
        \t\t"h": {
        \t\t\t"i": "j",
        \t\t\t"k": [
        \t\t\t\t"l",
        \t\t\t\t"m",
        \t\t\t\t"n"
        \t\t\t]
        \t\t}
        \t}
      JSON
    end
  end
end
