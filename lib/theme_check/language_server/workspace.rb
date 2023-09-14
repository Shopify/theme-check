# frozen_string_literal: true

require 'set'

module ThemeCheck
  module LanguageServer
    # In many projects there will be several theme folders, possibly deep down
    # within the directory structure. We want to be able to run checks on all
    # of the themes simultaneously while still not mixing files from different
    # themes in completion providers or whole-theme checks.
    #
    # This class is responsible for maintaining a general storage and providing
    # views of the theme folder of individual files or sets of files for the
    # diagnostics engine.
    #
    class Workspace < VersionedInMemoryStorage
      def initialize(root)
        super({}, root)
        @themes = Set.new # Set<relative_path>
      end

      def access(absolute_path)
        workspace_path = relative_path(absolute_path)
        folder = find_theme(workspace_path)
        folder ||= access_theme(absolute_path)
        [workspace_path, folder]
      end

      def find_theme(absolute_or_workspace_path)
        folder = path(absolute_or_workspace_path).relative_path_from(@root)
        folder = folder.dirname until @themes.include?(folder.to_s) || folder.to_s == '.' || folder.to_s == '/'
        folder.to_s if @themes.include?(folder.to_s)
      end

      def theme_view(workspace_path)
        folder = find_theme(workspace_path)
        raise ArgumentError, "Folder not found for #{workspace_path}" unless folder

        ThemeView.new(self, folder)
      end

      def filter_files(relative_folder, workspace_paths)
        workspace_paths
          .select { |path| path_contains?(relative_folder, path) }
          .map { |path| Pathname.new(path).relative_path_from(relative_folder).to_s }
      end

      def group_paths_by_theme_view(absolute_paths)
        absolute_paths
          .filter { |path| find_theme(relative_path(path)) }
          .group_by { |path| find_theme(relative_path(path)) }
          .map { |folder, paths| [ThemeView.new(self, folder), paths.map! { |p| path(p) }] }
      end

      private

      def path_contains?(super_path, sub_path)
        sub_path = Pathname.new(sub_path)
        sub_path = sub_path.dirname until sub_path.to_s == super_path.to_s || sub_path.to_s == '.' || sub_path.to_s == '/'
        sub_path.to_s == super_path.to_s
      end

      def intersecting?(path1, path2)
        path_contains?(path1, path2) || path_contains?(path2, path1)
      end

      def conflicting_theme_root?(absolute_path)
        @themes.any? do |folder|
          intersecting?(path(folder), absolute_path)
        end
      end

      def ascend_to_theme_folder(absolute_path)
        Pathname.new(absolute_path).ascend do |path|
          return path if ThemeCheck::Config.is_theme_folder?(path)
          # the config file can be outside the workspace, but not the theme folder
          break if path == @root
        end
      end

      def access_theme(absolute_path)
        folder = ascend_to_theme_folder(absolute_path)
        return unless folder
        return if conflicting_theme_root?(folder)

        IOMessenger.log("Adding theme folder '#{folder}'")
        add_theme_files(folder)
        @themes.add(relative_path(folder))
      end

      def config_for_path(absolute_path)
        root = ThemeCheck::Config.find(absolute_path) || @root
        ThemeCheck::Config.from_path(root)
      end

      def add_theme_files(absolute_path)
        config = config_for_path(absolute_path)

        # Make a real FS to get the files from the snippets folder
        fs = ThemeCheck::FileSystemStorage.new(
          config.root, # Use config.root here so ignored_patterns match correctly
          ignored_patterns: config.ignored_patterns
        )

        fs.files
          .map { |fn| [relative_path(config.root.join(fn)), fs.read(fn)] }
          .each { |workspace_path, content| write(workspace_path, content, nil) }
      end
    end
  end
end
