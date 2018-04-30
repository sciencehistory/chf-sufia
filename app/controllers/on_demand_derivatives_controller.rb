# Use for our whole-work multi-image derivatives: PDF, zip. To create them on
# demand, via a background job, and provide JSON status messages for front-end
# to display progress and redirect to download, etc.
class OnDemandDerivativesController < ApplicationController

  # Returns a JSON hash with status of on-demand derivative, including a URL
  # if it's available now.
  def pdf
    id = params.require(:id)

    checksum = checksum_for_work_id(id)

    record = find_or_create_record(id, "pdf", checksum)

    render json: record.as_json(methods: :url)
  end


  protected

  # Finds or creates the status record, and also kicks off the bg job if creating the status
  # record. Also if the status record is stale, will delete it and create a new one.
  def find_or_create_record(id, type, checksum, retry_count: 0)
    if retry_count > 10
      # what the heck is going on? Let's keep us from infinitely doing it and taking up all the CPU
      raise StandardError.new("Tried to find/create an OnDemandDerivative record too many times for work #{id}")
    end

    record = OnDemandDerivative.where(work_id: id, deriv_type: type).first
    if record.nil?
      record = OnDemandDerivative.create(work_id: id, deriv_type: type, status: :in_progress, checksum: checksum)
      CreateWorkPdfJob.perform_later(record)
    end

    if ( record.in_progress? && (Time.now - record.updated_at) > OnDemandDerivative::STALE_IN_PROGRESS_SECONDS ) ||
       ( record.error? && (Time.now - record.updated_at) > OnDemandDerivative::ERROR_RETRY_SECONDS ) ||
       ( record.success? && (record.checksum != checksum || !record.file_exists? ))
          # It's stale, delete it!
          record.delete
          # and try again
          record = find_or_create_record(id, type, checksum, retry_count: retry_count + 1)
    end

    return record
  rescue ActiveRecord::RecordNotUnique
    # race condition, someone else created it, no biggy
    return find_or_create_record(id, type, checksum, retry_count: retry_count + 1)
  end

  # We gotta get all it's representatives, and compile all their checksums, to make
  # sure checksum changes if members have changed at all. This will be a couple
  # Solr fetches.
  def checksum_for_work_id(work_id)
    presenter = CurationConcerns::GenericWorkShowPresenter.new(
      SolrDocument.find(work_id),
      Ability.new(current_user)
    )
    representative_checksums = presenter.work_presenters.collect(&:representative_checksum).compact

    Digest::MD5.hexdigest(representative_checksums.join("-"))
  end


end
