module Chf
  module Import
  # Imports a Sufia 6.0-exported GenericFile into a Sufia PCDM GernericWork and FileSet
    class GenericFileTranslator < ::Sufia::Import::GenericFileTranslator

      def initialize(settings)
        super
        # use local workbuilder
        @work_builder = WorkBuilder.new
      end

    end
  end
end
