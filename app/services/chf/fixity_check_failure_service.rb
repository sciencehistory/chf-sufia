module CHF
  class FixityCheckFailureService
    attr_reader :log_date, :checksum_audit_log, :file_set

    def initialize(file_set, checksum_audit_log:)
      @file_set = file_set
      @checksum_audit_log = checksum_audit_log
    end

    def call
      # send an email to digital-tech
      ActionMailer::Base.mail(from: "digital-tech@chemheritage.org",
                              to: "digital-tech@chemheritage.org",
                              subject: subject,
                              content_type: "text/html",
                              body: message).deliver_later

      # Send in-app messages to all admins. Who knows if sendio will
      # block the email anyway.
      admin_role = Role.where(name: 'admin').first
      if admin_role
        admin_role.users.each do |user|
          ::User.audit_user.send_message(user, message, subject)
        end
      end
    end

    def message
      <<-EOF
<p>hostname: #{`hostname`.chomp}</p>

<p>Fixity check failure at #{log_created_at}<br>
  for: <a href="#{checked_uri}/fcr:metadata">#{checked_uri}/fcr:metadata</a></p>

<p>Expected fixity result: #{expected_result}</p>

<p>work:
  #{works_message}</p>


<p>file_set: #{file_set_id} #{file_set_title}
  <a href="#{file_set_app_path}">#{file_set_app_path}</a>
  <a href="#{file_set.try(:uri)}/fcr:metadata">#{file_set.try(:uri)}/fcr:metadata</a></p>

<p>file: #{file_id}
  <a href="#{file_fedora_metadata_uri}">#{file_fedora_metadata_uri}</a></p>

<p>Logged in ChecksumAuditLog: #{ERB::Util.html_escape checksum_audit_log.inspect}</p>
  EOF
    end

    def subject
      "FIXITY CHECK FAILURE: #{Socket.gethostname}: #{file_set_title}"
    end

    protected

    def file_id
      checksum_audit_log.file_id
    end

    def works
      file_set.try(:in_works) || []
    end

    def works_message
      works.to_a.collect do |w|
        "  #{w.try(:title).try(:first)} #{w.id} <a href='#{Rails.application.routes.url_helpers.curation_concerns_generic_work_path(w)}'>#{Rails.application.routes.url_helpers.curation_concerns_generic_work_path(w)}</a>"
      end.join("\n")
    end

    def file_fedora_metadata_uri
      file_uri = Hydra::PCDM::File.translate_id_to_uri.call(file_id)
      file_uri && "#{file_uri}/fcr:metadata"
    end

    def log_created_at
      checksum_audit_log.try(:created_at).try(:in_time_zone).try(:to_s)
    end

    def file_set_id
      checksum_audit_log.try(:file_set_id)
    end

    def file_set_title
      file_set.try(:title).try(:first)
    end

    def file_set_app_path
      Rails.application.routes.url_helpers.curation_concerns_file_set_path(works.first, file_set) if file_set && works.present?
    end

    def checked_uri
      checksum_audit_log.try(:checked_uri)
    end

    def expected_result
      checksum_audit_log.try(:expected_result)
    end
  end
end
