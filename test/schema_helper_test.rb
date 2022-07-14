# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class SchemaHelperTest < Minitest::Test
    def test_set
      assert_equal({ "a" => { "b" => 1 } }, SchemaHelper.set({}, 'a.b', 1))
      assert_equal({ "a" => { "b" => 1 } }, SchemaHelper.set({}, ['a', 'b'], 1))
      assert_equal({ "a" => { "b" => 1 } }, SchemaHelper.set({ "a" => { "b" => 0 } }, 'a.b', 1))
      assert_equal({ "a" => { "1" => "str" } }, SchemaHelper.set({ "a" => "b" }, 'a.1', "str"))
      assert_equal({ "a" => { "b" => "str" } }, SchemaHelper.set({ "a" => "b" }, 'a.b', "str"))
      assert_equal({ "a" => 1 }, SchemaHelper.set({ "a" => { "b" => 1 } }, 'a', 1))
    end

    def test_delete
      hash = { "a" => { "b" => 111, "c" => 222 } }
      assert_equal(111, SchemaHelper.delete(hash, 'a.b'))
      assert_equal(222, SchemaHelper.delete(hash, ['a', 'c']))
      assert_nil(SchemaHelper.delete(hash, 'a.b'))
      assert_equal({ "a" => {} }, hash)
    end

    def test_schema_corrector_recursively_adds_keys_through_arrays
      schema = {
        "array" => [
          {},
          {},
          {},
        ],
      }
      assert_equal(
        {
          "array" => [
            { "a" => 1 },
            { "a" => 1 },
            { "a" => 1 },
          ],
        },
        SchemaHelper.schema_corrector(schema, "array.a", 1),
      )
    end

    def test_schema_corrector_deeply_adds_keys
      schema = {
        "deep" => {
          "object" => {},
        },
      }
      assert_equal(
        {
          "deep" => {
            "object" => {
              "a" => 1,
            },
          },
        },
        SchemaHelper.schema_corrector(schema, ["deep", "object", "a"], 1),
      )
    end

    def test_schema_corrector_deeply_adds_keys_in_array_by_id
      schema = {
        "deep" => [
          { "id" => "hi" },
          { "id" => "oh" },
        ],
      }
      assert_equal(
        {
          "deep" => [
            { "id" => "hi", "ho" => "ho" },
            { "id" => "oh" },
          ],
        },
        SchemaHelper.schema_corrector(schema, "deep.hi.ho", "ho")
      )
    end
  end
end
