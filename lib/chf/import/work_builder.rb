# Builder for generating a work incluing permissions
#
module Chf
  module Import
    class WorkBuilder < Sufia::Import::WorkBuilder
      attr_accessor :date_of_work_builder, :credit_builder, :inscription_builder

      def initialize
        super
        @date_of_work_builder = DateOfWorkBuilder.new
        @credit_builder = CreditBuilder.new
        @inscription_builder = InscriptionBuilder.new
      end

      def build(gf_metadata)
        work = Sufia.primary_work_type.new
        permission_builder = Sufia::Import::PermissionBuilder.new
        data = gf_metadata.deep_symbolize_keys
        data.delete(:batch_id) # This attribute was removed in sufia 7
        data.delete(:versions) # works don't have versions; these are used in file set builder
        # "All rights reserved" was changed to a legit URI
        if data[:rights].delete("All rights reserved")
          data[:rights] << "http://www.europeana.eu/portal/rights/rr-r.html"
        end
        # These URIs may look the same, but we accidentally have non-breaking hyphens in there!
        # 'In Copyright - EU Orphan Work' => 'http://rightsstatements.org/vocab/InC­OW­EU/1.0/',
        if data[:rights].delete('http://rightsstatements.org/vocab/InC­OW­EU/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/InC-OW-EU/1.0/'
        end
        # 'In Copyright - Educational Use Permitted'
        if data[:rights].delete('http://rightsstatements.org/vocab/InC­EDU/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/InC-EDU/1.0/'
        end
        # 'In Copyright - Non­Commercial Use Permitted'
        if data[:rights].delete('http://rightsstatements.org/vocab/InC­NC/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/InC-NC/1.0/'
        end
        # 'In Copyright - Rights­holder(s) Unlocatable or Unidentifiable'
        if data[:rights].delete('http://rightsstatements.org/vocab/InC­RUU/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/InC-RUU/1.0/'
        end
        # 'No Copyright - Contractual Restrictions'
        if data[:rights].delete('http://rightsstatements.org/vocab/NoC­CR/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/NoC-CR/1.0/'
        end
        # 'Out Of Copyright - Non­Commercial Use Only'
        if data[:rights].delete('http://rightsstatements.org/vocab/OOC­NC/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/NoC-NC/1.0/'
        end
        # 'No Copyright - Other Known Legal Restrictions'
        if data[:rights].delete('http://rightsstatements.org/vocab/NoC­OKLR/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/'
        end
        # No Copyright - United States
        if data[:rights].delete('http://rightsstatements.org/vocab/NoC­US/1.0/')
          data[:rights] << 'http://rightsstatements.org/vocab/NoC-US/1.0/'
        end

        work.apply_depositor_metadata(data.delete(:depositor))
        permission_builder.build(work, data.delete(:permissions))
        date_of_work_builder.build(work, data.delete(:date_of_work))
        credit_builder.build(work, data.delete(:additional_credit))
        inscription_builder.build(work, data.delete(:inscription))
        work.update_attributes(data)

        work
      end
    end
  end
end
