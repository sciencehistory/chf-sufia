class Sufia::BatchUploadsController < ApplicationController
  include Sufia::BatchUploadsControllerBehavior

  self.work_form_service = ::BatchUploadFormService
  self.curation_concern_type = work_form_service.form_class.model_class

    # Make browse-everything work on batch upload, by over-riding this method to do what it should.
    # Inserted to override Sufia 7.4.0©, using code suggested by PSU:
    # https://github.com/psu-stewardship/scholarsphere/commit/5529a502758e1638b4da3e14e3347692a2b46ff8
    def attributes_for_actor
      attributes = super
      # If they selected a BrowseEverything file, but then clicked the
      # remove button, it will still show up in `selected_files`, but
      # it will no longer be in uploaded_files. By checking the
      # intersection, we get the files they added via BrowseEverything
      # that they have not removed from the upload widget.
      uploaded_files = params.fetch(:uploaded_files, [])
      selected_files = params.fetch(:selected_files, {}).values
      browse_everything_urls = uploaded_files &
        selected_files.map { |f| f[:url] }

      # we need the hash of files with url and file_name
      browse_everything_files = selected_files
        .select { |v| uploaded_files.include?(v[:url]) }

      attributes[:remote_files] = browse_everything_files
      # Strip out any BrowseEverthing files from the regular uploads.
      attributes[:uploaded_files] = uploaded_files -
        browse_everything_urls
      attributes
    end

    protected

    # Overridden from sufia using scholarsphere code, to use our custom 5-arg job.
    # https://github.com/psu-stewardship/scholarsphere/commit/5529a502758e1638b4da3e14e3347692a2b46ff8
    def create_update_job(_klass)
      log = Sufia::BatchCreateOperation.create!(user: current_user,
                                                operation_type: 'Batch Create')
      # ActionController::Parameters are not serializable, so cast to a hash
      BatchCreateJob.perform_later(current_user,
                                   params[:title].permit!.to_h,
                                   params.fetch(:resource_type, {}).permit!.to_h,
                                   attributes_for_actor.to_h,
                                   log)
    end

end
