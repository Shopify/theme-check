# frozen_string_literal: true
require "optparse"

module PlatformosCheck
  class Cli
    class Abort < StandardError; end

    FORMATS = [:text, :json]

    attr_accessor :path

    def initialize
      @path = "."
      @command = :check
      @include_categories = []
      @exclude_categories = []
      @auto_correct = false
      @update_docs = false
      @config_path = nil
      @fail_level = :error
      @format = :text
    end

    def option_parser(parser = OptionParser.new, help: true)
      return @option_parser if defined?(@option_parser)
      @option_parser = parser
      @option_parser.banner = "Usage: theme-check [options] [/path/to/your/theme]"

      @option_parser.separator("")
      @option_parser.separator("Basic Options:")
      @option_parser.on(
        "-C", "--config PATH",
        "Use the config provided, overriding .theme-check.yml if present",
        "Use :theme_app_extension to use default checks for theme app extensions"
      ) { |path| @config_path = path }
      @option_parser.on(
        "-o", "--output FORMAT", FORMATS,
        "The output format to use. (text|json, default: text)"
      ) { |format| @format = format.to_sym }
      @option_parser.on(
        "-c", "--category CATEGORY", Check::CATEGORIES, "Only run this category of checks",
        "Runs checks matching all categories when specified more than once"
      ) { |category| @include_categories << category.to_sym }
      @option_parser.on(
        "-x", "--exclude-category CATEGORY", Check::CATEGORIES, "Exclude this category of checks",
        "Excludes checks matching any category when specified more than once"
      ) { |category| @exclude_categories << category.to_sym }
      @option_parser.on(
        "-a", "--auto-correct",
        "Automatically fix offenses"
      ) { @auto_correct = true }
      @option_parser.on(
        "--fail-level SEVERITY", [:crash] + Check::SEVERITIES,
        "Minimum severity (error|suggestion|style) for exit with error code"
      ) do |severity|
        @fail_level = severity.to_sym
      end

      @option_parser.separator("")
      @option_parser.separator("Miscellaneous:")
      @option_parser.on(
        "--init",
        "Generate a .theme-check.yml file"
      ) { @command = :init }
      @option_parser.on(
        "--print",
        "Output active config to STDOUT"
      ) { @command = :print }
      @option_parser.on(
        "--update-docs",
        "Update Theme Check docs (objects, filters, and tags)"
      ) { @update_docs = true }
      @option_parser.on(
        "-h", "--help",
        "Show this. Hi!"
      ) { @command = :help } if help
      @option_parser.on(
        "-l", "--list",
        "List enabled checks"
      ) { @command = :list }
      @option_parser.on(
        "-v", "--version",
        "Print Theme Check version"
      ) { @command = :version }

      if ENV["PLATFORMOS_CHECK_DEBUG"]
        @option_parser.separator("")
        @option_parser.separator("Debugging:")
        @option_parser.on(
          "--profile",
          "Output a profile to STDOUT compatible with FlameGraph."
        ) { @command = :profile }
      end

      @option_parser.separator("")
      @option_parser.separator(<<~EOS)
        Description:
            Theme Check helps you follow Shopify Themes & Liquid best practices by analyzing the
            Liquid & JSON inside your theme.

            You can configure checks in the .theme-check.yml file of your theme root directory.
      EOS

      @option_parser
    end

    def parse(argv)
      @path = option_parser.parse(argv).first || "."
    rescue OptionParser::InvalidArgument => e
      abort(e.message)
    end

    def run!
      unless [:version, :init, :help].include?(@command)
        @config = if @config_path
          PlatformosCheck::Config.new(
            root: @path,
            configuration: PlatformosCheck::Config.load_config(@config_path)
          )
        else
          PlatformosCheck::Config.from_path(@path)
        end
        @config.include_categories = @include_categories unless @include_categories.empty?
        @config.exclude_categories = @exclude_categories unless @exclude_categories.empty?
        @config.auto_correct = @auto_correct
      end

      send(@command)
    end

    def run
      run!
      exit(0)
    rescue Abort => e
      if e.message.empty?
        exit(1)
      else
        abort(e.message)
      end
    rescue PlatformosCheckError => e
      STDERR.puts(e.message)
      exit(2)
    end

    def self.parse_and_run!(argv)
      cli = new
      cli.parse(argv)
      cli.run!
    end

    def self.parse_and_run(argv)
      cli = new
      cli.parse(argv)
      cli.run
    end

    def list
      puts @config.enabled_checks
    end

    def version
      puts PlatformosCheck::VERSION
    end

    def init
      dotfile_path = PlatformosCheck::Config.find(@path)
      if dotfile_path.nil?
        config_name = @config_path || "default"
        File.write(
          File.join(@path, PlatformosCheck::Config::DOTFILE),
          File.read(PlatformosCheck::Config.bundled_config_path(config_name))
        )

        puts "Writing new #{PlatformosCheck::Config::DOTFILE} to #{@path}"
      else
        raise Abort, "#{PlatformosCheck::Config::DOTFILE} already exists at #{@path}"
      end
    end

    def print
      puts YAML.dump(@config.to_h)
    end

    def help
      puts option_parser.to_s
    end

    def check(out_stream = STDOUT)
      update_docs

      STDERR.puts "Checking #{@config.root} ..."
      storage = PlatformosCheck::FileSystemStorage.new(@config.root, ignored_patterns: @config.ignored_patterns)
      theme = PlatformosCheck::Theme.new(storage)
      if theme.all.empty?
        raise Abort, "No theme files found."
      end
      analyzer = PlatformosCheck::Analyzer.new(theme, @config.enabled_checks, @config.auto_correct)
      analyzer.analyze_theme
      analyzer.correct_offenses
      print_with_format(theme, analyzer, out_stream)
      # corrections are committed after printing so that the
      # source_excerpts are still pointing to the uncorrected source.
      analyzer.write_corrections
      raise Abort, "" if analyzer.uncorrectable_offenses.any? do |offense|
        offense.check.severity_value <= Check.severity_value(@fail_level)
      end
    end

    def update_docs
      return unless @update_docs

      STDERR.puts 'Updating documentation...'

      PlatformosCheck::ShopifyLiquid::SourceManager.download
    end

    def profile
      require 'ruby-prof-flamegraph'

      result = RubyProf.profile do
        check(STDERR)
      end

      # Print a graph profile to text
      printer = RubyProf::FlameGraphPrinter.new(result)
      printer.print(STDOUT, {})
    rescue LoadError
      STDERR.puts "Profiling is only available in development"
    end

    def print_with_format(theme, analyzer, out_stream)
      case @format
      when :text
        PlatformosCheck::Printer.new(out_stream).print(theme, analyzer.offenses, @config.auto_correct)
      when :json
        PlatformosCheck::JsonPrinter.new(out_stream).print(analyzer.offenses)
      end
    end
  end
end
