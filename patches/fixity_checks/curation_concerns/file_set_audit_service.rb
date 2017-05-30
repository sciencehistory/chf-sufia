module CurationConcerns
  # Override CurationConcerns::FileSetAuditService to basically be our new backported
  # Hyrax::FileSetFixityCheckService, to catch parts of the current sufia stack
  # that try to use CurationConcerns::FileSetAuditService. Mainly
  # the views/curation_concerns/file_sets/_show_details partial.

  if Gem.loaded_specs["hyrax"]
    msg = "\n\nPlease check and make sure this fixity check patch is still needed at #{__FILE__}:#{__LINE__}\n\n"
    $stderr.puts msg
    Rails.logger.warn msg
  end

  class FileSetAuditService < Hyrax::FileSetFixityCheckService

    def audit(*args)
      fixity_check
    end


    def logged_audit_status
      Hyrax::FixityStatusPresenter.new(file_set.id).render_file_set_status
    end
  end
end
