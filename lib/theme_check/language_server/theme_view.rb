# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ThemeView < Storage
      attr_reader :root # Debug logging only

      def initialize(workspace, relative_folder)
        @root = workspace.root.join(relative_folder)
        @folder = Pathname.new(relative_folder)
        @workspace = workspace
        @files_access_count = 0
      end

      def path(relative_path)
        @workspace.path(workspace_path(relative_path))
      end

      def read(relative_path)
        @workspace.read(workspace_path(relative_path))
      end

      def read_version(relative_path)
        @workspace.read_version(workspace_path(relative_path))
      end

      def version(relative_path)
        @workspace.version(workspace_path(relative_path))
      end

      def write(relative_path, content, version)
        @workspace.write(workspace_path(relative_path), content, version)
      end

      def remove(relative_path)
        @workspace.remove(workspace_path(relative_path))
      end

      def mkdir(relative_path)
        @workspace.mkdir(workspace_path(relative_path))
      end

      def versioned?
        @workspace.versioned?
      end

      # Warning: not memoized, could pose a performance issue on large workspaces
      # if accessed many times in a single lint run.
      def files
        @files_access_count += 1
        IOMessenger.log("ThemeView.files accessed #{@files_access_count}x") if @files_access_count >= 5
        @workspace.filter_files(@folder, @workspace.files)
      end

      def directories
        files
          .flat_map { |relative_path| Pathname.new(relative_path).ascend.to_a }
          .map(&:to_s)
          .uniq
      end

      def opened_files
        @workspace.filter_files(@folder, @workspace.versions.keys)
      end

      def relative_path(absolute_path)
        Pathname.new(absolute_path).relative_path_from(@root).to_s
      end

      def folder_path(workspace_path)
        Pathname.new(workspace_path).relative_path_from(@folder).to_s
      end

      def workspace_path(relative_path)
        @folder.join(relative_path).to_s
      end

      def debugging
        hash = { }
        files.each do |file|
          hash[workspace_path(file)] = "#{read(file)&.size || '?'}c, #{version(file)}v"
        end
        hash
      end
    end
  end
end
