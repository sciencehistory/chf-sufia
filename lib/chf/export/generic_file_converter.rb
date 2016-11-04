module Chf
  module Export
    # Convert a GenericFile including metadata, permissions and version metadata into a PORO
    # so that the metadata can be exported in json format using to_json
    #
    class GenericFileConverter < Sufia::Export::GenericFileConverter
      # Create an instance of a GenericFile converter containing all the metadata for json export
      #
      # @param [GenericFile] gf file to be converted for export
      def initialize(gf)
        gf.reload # nested properties are coming back in duplicates.
        @id = gf.id
        @label = gf.label
        @depositor = gf.depositor
        @relative_path = gf.relative_path
        @import_url = gf.import_url
        @resource_type = gf.resource_type
        @title = gf.title
        @creator = gf.creator
        @contributor = gf.contributor
        @description = gf.description
        @rights = gf.rights
        @publisher = gf.publisher
        @date_created = gf.date_created
        @date_uploaded = gf.date_uploaded
        @date_modified = gf.date_modified
        @subject = gf.subject
        @language = gf.language
        @identifier = gf.identifier
        @based_near = gf.based_near
        @related_url = gf.related_url
        @bibliographic_citation = gf.bibliographic_citation
        @source = gf.source
        @batch_id = gf.batch.id if gf.batch
        @visibility = gf.visibility
        @versions = versions(gf)
        @permissions = permissions(gf)
        @artist = gf.artist
        @author = gf.author
        @addressee = gf.addressee
        @creator_of_work = gf.creator_of_work
        @interviewee = gf.interviewee
        @interviewer = gf.interviewer
        @manufacturer = gf.manufacturer
        @photographer = gf.photographer
        @place_of_interview = gf.place_of_interview
        @place_of_manufacture = gf.place_of_manufacture
        @place_of_publication = gf.place_of_publication
        @place_of_creation = gf.place_of_creation
        @admin_note = gf.admin_note
        @credit_line = gf.credit_line
        @division = gf.division
        @file_creator = gf.file_creator
        @genre_string = gf.genre_string
        @extent = gf.extent
        @medium = gf.medium
        @physical_container = gf.physical_container
        @rights_holder = gf.rights_holder
        @series_arrangement = gf.series_arrangement
        @date_of_work = date_of_work(gf)
        @inscription = inscription(gf)
        @additional_credit = credit(gf)
      end

      private

        def date_of_work(gf)
          gf.date_of_work.map { |c| TimeSpanConverter.new(c) }
        end

        def inscription(gf)
          gf.inscription.map { |c| InscriptionConverter.new(c) }
        end

        def credit(gf)
          gf.additional_credit.map { |c| CreditConverter.new(c) }
        end

    end
  end
end
