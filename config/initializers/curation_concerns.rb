CurationConcerns.configure do |config|
  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  config.working_path = Rails.env.production? ? '/tmp/working' : (ENV['SUFIA_TMP_PATH'] || '/tmp')

  CurationConcerns.config.callback.set(:after_fixity_check_failure) do |file_set, checksum_audit_log:|
    CHF::FixityCheckFailureService.new(file_set, checksum_audit_log: checksum_audit_log).call
  end
end

