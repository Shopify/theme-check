module ThemeCheck
  module LanguageServer
    class FileRenameHandler 
      include URIHelper

      def to_workspace_edit(storage, relative_paths)
        {
          documentChanges: to_text_document_edits(storage, relative_paths)
        }
      end


      def to_text_document_edits(storage, relative_paths)
        snippets = relative_paths
          .map { |(old_path, new_path)| old_path }
          .filter{ |path| path.start_with?("snippets/")  }
          .map{ |path| path.sub(/^snippets\//, '').sub(/.liquid$/, '') }
          
        theme = ThemeCheck::Theme.new(storage)

        binding.pry

        # find all files that contain either {% render 'snippetName' %} or {% include 'snippetName' %}
        theme.liquid.map do |liquid_file|
          {
            textDocument: {
              uri: file_uri(liquid_file.path)
              version: storage.version(liquid_file.relative_path)
            },
            edits: to_text_edits(liquid_file, storage, relative_paths)
          }
        end
        #.reject(te => te.edits.empty?)
      end

      def to_text_edits(liquid_file, storage, relative_paths)
        node_finder = ...
        visitor = ...
        visitor.visit
        const [renderNodes, assetUrlNodes, sectionsNodes] = render_finder
        ## ... 
        text_edits = renderNodeTextEdits + assetUrlTextEdits + sectionsTextEdits
      end
    end
  end
end