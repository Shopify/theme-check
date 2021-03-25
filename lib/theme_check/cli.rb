# frozen_string_literal: true
module ThemeCheck
  class Cli
    class Abort < StandardError; end

    USAGE = <<~END
      Usage: theme-check [options] /path/to/your/theme

      Basic Options:
        -C, --config <path>                  Use the config provided, overriding .theme-check.yml if present
        -c, --category <category>            Only run this category of checks
        -x, --exclude-category  <category>   Exclude this category of checks
        -a, --auto-correct                   Automatically fix offenses

      Miscellaneous:
        --init                               Generate a .theme-check.yml file
        --print-config                       Output active config to STDOUT
        -h, --help                           Show this. Hi!
        -l, --list                           List enabled checks
        -v, --version                        Print Theme Check version

      Description:
        Theme Check helps you follow Shopify Themes & Liquid best practices by analyzing the
        Liquid & JSON inside your theme.

        You can configure checks in the .theme-check.yml file of your theme root directory.
    END

    def run(argv)
      @path = "."

      command = :check
      only_categories = []
      exclude_categories = []
      auto_correct = false
      config_path = nil

      args = argv.dup
      while (arg = args.shift)
        case arg
        when "--help", "-h"
          raise Abort, USAGE
        when "--version", "-v"
          command = :version
        when "--config", "-C"
          config_path = Pathname.new(args.shift)
        when "--category", "-c"
          only_categories << args.shift.to_sym
        when "--exclude-category", "-x"
          exclude_categories << args.shift.to_sym
        when "--list", "-l"
          command = :list
        when "--auto-correct", "-a"
          auto_correct = true
        when "--init"
          command = :init
        when "--print"
          command = :print
        else
          @path = arg
        end
      end

      unless [:version, :init].include?(command)
        @config = if config_path.present?
          ThemeCheck::Config.new(
            root: @path,
            configuration: ThemeCheck::Config.load_file(config_path)
          )
        else
          ThemeCheck::Config.from_path(@path)
        end
        @config.only_categories = only_categories
        @config.exclude_categories = exclude_categories
        @config.auto_correct = auto_correct
      end

      send(command)
    end

    def run!(argv)
      run(argv)
    rescue Abort => e
      if e.message.empty?
        exit(1)
      else
        abort(e.message)
      end
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

    def check
      puts "Checking #{@config.root} ..."
      storage = ThemeCheck::FileSystemStorage.new(@config.root, ignored_patterns: @config.ignored_patterns)
      theme = ThemeCheck::Theme.new(storage)
      if theme.all.empty?
        raise Abort, "No templates found.\n#{USAGE}"
      end
      analyzer = ThemeCheck::Analyzer.new(theme, @config.enabled_checks, @config.auto_correct)
      analyzer.analyze_theme
      analyzer.correct_offenses
      ThemeCheck::Printer.new.print(theme, analyzer.offenses, @config.auto_correct)
      raise Abort, "" if analyzer.uncorrectable_offenses.any?
    end
  end
end
