# frozen_string_literal: true
require "optparse"

module ThemeCheck
  class Cli
    class Abort < StandardError; end

    attr_accessor :path

    def initialize
      @path = "."
      @command = :check
      @only_categories = []
      @exclude_categories = []
      @auto_correct = false
      @config_path = nil
    end

    def option_parser(parser = OptionParser.new, help: true)
      return @option_parser if defined?(@option_parser)
      @option_parser = parser
      @option_parser.banner = "Usage: theme-check [options] [/path/to/your/theme]"

      @option_parser.separator("")
      @option_parser.separator("Basic Options:")
      @option_parser.on(
        "-C", "--config PATH",
        "Use the config provided, overriding .theme-check.yml if present"
      ) { |path| @config_path = path }
      @option_parser.on(
        "-c", "--category CATEGORY",
        "Only run this category of checks"
      ) { |category| @only_categories << category.to_sym }
      @option_parser.on(
        "-x", "--exclude-category CATEGORY",
        "Exclude this category of checks"
      ) { |category| @exclude_categories << category.to_sym }
      @option_parser.on(
        "-a", "--auto-correct",
        "Automatically fix offenses"
      ) { @auto_correct = true }

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
    end

    def run!
      unless [:version, :init, :help].include?(@command)
        @config = if @config_path
          ThemeCheck::Config.new(
            root: @path,
            configuration: ThemeCheck::Config.load_file(@config_path)
          )
        else
          ThemeCheck::Config.from_path(@path)
        end
        @config.only_categories = @only_categories
        @config.exclude_categories = @exclude_categories
        @config.auto_correct = @auto_correct
      end

      send(@command)
    end

    def run
      run!
    rescue Abort => e
      if e.message.empty?
        exit(1)
      else
        abort(e.message)
      end
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
      puts ThemeCheck::VERSION
    end

    def init
      dotfile_path = ThemeCheck::Config.find(@path)
      if dotfile_path.nil?
        File.write(File.join(@path, ThemeCheck::Config::DOTFILE), File.read(ThemeCheck::Config::DEFAULT_CONFIG))

        puts "Writing new #{ThemeCheck::Config::DOTFILE} to #{@path}"
      else
        raise Abort, "#{ThemeCheck::Config::DOTFILE} already exists at #{@path}."
      end
    end

    def print
      puts YAML.dump(@config.to_h)
    end

    def help
      puts option_parser.to_s
    end

    def check
      puts "Checking #{@config.root} ..."
      storage = ThemeCheck::FileSystemStorage.new(@config.root, ignored_patterns: @config.ignored_patterns)
      theme = ThemeCheck::Theme.new(storage)
      if theme.all.empty?
        raise Abort, "No templates found."
      end
      analyzer = ThemeCheck::Analyzer.new(theme, @config.enabled_checks, @config.auto_correct)
      analyzer.analyze_theme
      analyzer.correct_offenses
      ThemeCheck::Printer.new.print(theme, analyzer.offenses, @config.auto_correct)
      raise Abort, "" if analyzer.uncorrectable_offenses.any?
    end
  end
end
