# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def test_load_file_uses_provided_config
    storage = make_file_system_storage(".theme-check.yml" => <<~END)
      TemplateLength:
        enabled: false
    END
    config = PlatformosCheck::Config.from_path(storage.root).to_h
    refute(config.dig("TemplateLength", "enabled"))
  end

  def test_load_file_in_parent_dir
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        TemplateLength:
          enabled: false
      END
      "dist/templates/index.liquid" => "",
    )
    config = PlatformosCheck::Config.from_path(storage.root.join("dist")).to_h
    refute(config.dig("TemplateLength", "enabled"))
  end

  def test_missing_file
    storage = make_file_system_storage
    config = PlatformosCheck::Config.from_path(storage.root)
    assert_equal(PlatformosCheck::Config.default, config.to_h)
  end

  def test_from_path_uses_empty_config_when_config_file_is_missing
    PlatformosCheck::Config.expects(:new).with(root: 'theme/')
    PlatformosCheck::Config.from_path('theme/')
  end

  def test_from_string
    config = PlatformosCheck::Config.from_string(<<~CONFIG)
      TemplateLength:
        enabled: false
    CONFIG
    refute(config.to_h.dig("TemplateLength", "enabled"))
  end

  def test_from_hash
    config = PlatformosCheck::Config.from_hash({
      "TemplateLength" => {
        "enabled" => false,
      },
    })
    refute(config.to_h.dig("TemplateLength", "enabled"))
  end

  def test_enabled_checks_excludes_disabled_checks
    config = PlatformosCheck::Config.new(root: ".", configuration: { "MissingTemplate" => { "enabled" => false } })
    refute(check_enabled?(config, PlatformosCheck::MissingTemplate))
  end

  def test_root
    config = PlatformosCheck::Config.new(root: ".", configuration: { "root" => "dist" })
    assert_equal(Pathname.new("dist"), config.root)
  end

  def test_empty_file
    storage = make_file_system_storage(".theme-check.yml" => "")
    config = PlatformosCheck::Config.from_path(storage.root)
    assert_equal(PlatformosCheck::Config.default, config.to_h)
  end

  def test_root_from_config
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        root: dist
      END
      "dist/templates/index.liquid" => "",
    )
    config = PlatformosCheck::Config.from_path(storage.root)
    assert_equal(storage.root.join("dist"), config.root)
  end

  def test_relative_extends
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        root: src
        extends: :nothing
        SyntaxError:
          enabled: false
        MatchingTranslations:
          enabled: false
      END
      "dist/.theme-check.yml" => <<~END,
        root: '.'
        extends: ../.theme-check.yml
        MatchingTranslations:
          enabled: true
      END
      "dist/templates/index.liquid" => "",
    )

    dist_config = PlatformosCheck::Config.from_path(storage.root.join('dist'))
    assert(dist_config.to_h.dig('MatchingTranslations', 'enabled'))
    refute(dist_config.to_h.dig('SyntaxError', 'enabled'))
    assert_equal(storage.root.join('dist'), dist_config.root)

    root_config = PlatformosCheck::Config.from_path(storage.root)
    refute(root_config.to_h.dig('MatchingTranslations', 'enabled'))
    refute(root_config.to_h.dig('SyntaxError', 'enabled'))
    assert_equal(storage.root.join('src'), root_config.root)
  end

  def test_relative_extends_reused_root_is_relative_to_found_root
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        root: src
      END
      "project1/.theme-check.yml" => <<~END,
        extends: ../.theme-check.yml
      END
      "project2/.theme-check.yml" => <<~END,
        extends: ../.theme-check.yml
      END
    )

    project1_config = PlatformosCheck::Config.from_path(storage.root.join('project1'))
    assert_equal(storage.root.join('project1/src'), project1_config.root)

    project2_config = PlatformosCheck::Config.from_path(storage.root.join('project2'))
    assert_equal(storage.root.join('project2/src'), project2_config.root)
  end

  def test_absolute_path_config
    storage1 = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        SyntaxError:
          enabled: false
      END
    )
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        extends: #{storage1.root.join('.theme-check.yml')}
      END
    )

    config = PlatformosCheck::Config.from_path(storage.root)
    refute(config.to_h.dig('SyntaxError', 'enabled'))
  end

  def test_picks_nearest_config
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        TemplateLength:
          enabled: false
      END
      "src/.theme-check.yml" => <<~END,
        TemplateLength:
          enabled: true
      END
    )
    config = PlatformosCheck::Config.from_path(storage.root.join("src"))
    assert_equal(storage.root.join("src"), config.root)
    assert(check_enabled?(config, PlatformosCheck::TemplateLength))
  end

  def test_respects_provided_root
    config = PlatformosCheck::Config.from_path(__dir__)
    assert_equal(Pathname.new(__dir__), config.root)
  end

  def test_enabled_checks_returns_default_checks_for_empty_config
    mock_default_config("SyntaxError" => { "enabled" => true })
    config = PlatformosCheck::Config.new(root: ".")
    assert(check_enabled?(config, PlatformosCheck::SyntaxError))
  end

  def test_warn_about_unknown_config
    mock_default_config("SyntaxError" => { "enabled" => true })
    PlatformosCheck::Config.any_instance
      .expects(:warn).with("unknown configuration: unknown")
    PlatformosCheck::Config.any_instance
      .expects(:warn).with("unknown configuration: SyntaxError.unknown")
    PlatformosCheck::Config.new(
      root: ".",
      configuration: {
        "unknown" => ".",
        "SyntaxError" => { "unknown" => false },
        "CustomCheck" => { "unknown" => false },
      }
    )
  end

  def test_warn_about_type_mismatch
    mock_default_config(
      "root" => ".",
      "SyntaxError" => { "enabled" => true },
      "TemplateLength" => { "enabled" => true },
    )
    PlatformosCheck::Config.any_instance
      .expects(:warn).with("bad configuration type for root: expected a String, got []")
    PlatformosCheck::Config.any_instance
      .expects(:warn).with("bad configuration type for SyntaxError.enabled: expected true or false, got nil")
    PlatformosCheck::Config.any_instance
      .expects(:warn).with("bad configuration type for TemplateLength: expected a Hash, got true")
    PlatformosCheck::Config.new(
      root: ".",
      configuration: {
        "root" => [],
        "SyntaxError" => { "enabled" => nil },
        "TemplateLength" => true,
      }
    )
  end

  def test_merge_configs
    mock_default_config(
      "root": ".",
      "ignore": [
        "node_modules",
      ],
      "SyntaxError" => {
        "enabled" => true,
        "muffin_mode" => "enabled",
      },
      "EmptyCheck" => {
        "enabled" => true,
      },
      "OtherCheck" => {
        "enabled" => true,
      },
    )
    config = PlatformosCheck::Config.new(
      root: ".",
      configuration: {
        "ignore": [
          "some_dir",
        ],
        "SyntaxError" => {
          "muffin_mode" => "maybe",
        },
        "EmptyCheck" => {},
      }
    )
    assert_equal({
      "ignore": [
        "some_dir",
      ],
      "SyntaxError" => {
        "enabled" => true,
        "muffin_mode" => "maybe",
      },
      "EmptyCheck" => {
        "enabled" => true,
      },
      "OtherCheck" => {
        "enabled" => true,
      },
      "root": ".",
    }, config.to_h)
  end

  def test_custom_check
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        include_categories: []
        require:
          - ./checks/custom_check.rb
        CustomCheck:
          enabled: true
      END
      "checks/custom_check.rb" => <<~END,
        module PlatformosCheck
          class CustomCheck < Check
          end
        end
      END
    )
    config = PlatformosCheck::Config.from_path(storage.root)
    assert(check_enabled?(config, PlatformosCheck::CustomCheck))
  end

  def test_custom_check_with_root
    storage = make_file_system_storage(
      ".config/.theme-check.yml" => <<~END,
        root: dist
        include_categories: []
        require:
          - ../checks/custom_check.rb
        CustomCheck:
          enabled: true
      END
      "dist/layout/theme.liquid" => "",
      "checks/custom_check.rb" => <<~END,
        module PlatformosCheck
          class CustomCheck < Check
          end
        end
      END
    )

    config = PlatformosCheck::Config.new(
      root: storage.root,
      configuration: PlatformosCheck::Config.load_config(storage.root.join('.config/.theme-check.yml'))
    )

    assert(check_enabled?(config, PlatformosCheck::CustomCheck))
  end

  def test_include_category
    config = PlatformosCheck::Config.new(root: ".")
    config.include_categories = [:liquid]
    assert(config.enabled_checks.any?)
    assert(config.enabled_checks.all? { |c| c.categories.include?(:liquid) })
  end

  def test_include_categories
    config = PlatformosCheck::Config.new(root: ".")
    config.include_categories = [:liquid, :performance]
    assert(config.enabled_checks.any?)
    assert(config.enabled_checks.all? { |c| c.categories.include?(:liquid) && c.categories.include?(:performance) })
    assert(config.enabled_checks.none? { |c| c.categories.include?(:liquid) && !c.categories.include?(:performance) })
  end

  def test_exclude_category
    config = PlatformosCheck::Config.new(root: ".")
    config.exclude_categories = [:liquid]
    assert(config.enabled_checks.any?)
    assert(config.enabled_checks.none? { |c| c.categories.include?(:liquid) })
  end

  def test_exclude_categories
    config = PlatformosCheck::Config.new(root: ".")
    config.exclude_categories = [:liquid, :performance]
    assert(config.enabled_checks.any?)
    assert(config.enabled_checks.none? { |c| c.categories.include?(:liquid) || c.categories.include?(:performance) })
  end

  def test_ignore
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        ignore:
          - node_modules
          - dist/*.json
      END
    )
    config = PlatformosCheck::Config.from_path(storage.root)
    assert_equal(["node_modules", "dist/*.json"], config.ignored_patterns)
  end

  def test_merged_ignored_patterns
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        extends: nothing
        ignore:
          - node_modules
          - dist/*.json
        MissingTemplate:
          enabled: true
          ignore:
            - 'snippets/foo.js'
      END
    )
    config = PlatformosCheck::Config.from_path(storage.root)
    missing_snippets_check = config.enabled_checks.find { |c| c.code_name == 'MissingTemplate' }
    assert_equal(
      ["snippets/foo.js", "node_modules", "dist/*.json"],
      missing_snippets_check.ignored_patterns
    )
  end

  private

  def check_enabled?(config, klass)
    config.enabled_checks.map(&:class).include?(klass)
  end

  def mock_default_config(config)
    PlatformosCheck::Config.stubs(:default).returns(config)
    PlatformosCheck::Config.stubs(:load_config).with(:default).returns(config)
    PlatformosCheck::Config.stubs(:load_config).with(":default").returns(config)
  end
end
