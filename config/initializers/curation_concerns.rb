CurationConcerns.configure do |config|
  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  config.working_path = Rails.env.production? ? '/tmp/working' : (ENV['SUFIA_TMP_PATH'] || '/tmp')

  CurationConcerns.config.callback.set(:after_fixity_check_failure) do |file_set, checksum_audit_log:|
    CHF::FixityCheckFailureService.new(file_set, checksum_audit_log: checksum_audit_log).call
  end
end

# We're actually overriding from the sufia-set Sufia::FileSetPresenter, to our
# own. to_prepare seems necessary to make it stick in dev.
Rails.application.config.to_prepare do
  CurationConcerns::MemberPresenterFactory.file_presenter_class = CHF::FileSetPresenter
  # And we also need to set the work_presenter_class, so it comes back from
  # GenericWork#member_presenters. This is actually a custom CHF one despite the
  # namespace.
  CurationConcerns::MemberPresenterFactory.work_presenter_class = CurationConcerns::GenericWorkShowPresenter
end

