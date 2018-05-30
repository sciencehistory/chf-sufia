# Take a file_set and a single "remote" file (via browse_everything), and attaches
# the bytestream to the fileset. An extraction of CreateWithRemoteFilesActor, to be on a single file, in
# it's own job, and not launch any other jobs. But with all
# the fedora objects created in our custom attach_file_sets_job (which then calls this one),
# cause attaching file sets to a work can't be done concurrently.
#
# https://github.com/samvera/sufia/blob/v7.4.0/app/actors/sufia/create_with_remote_files_actor.rb
#
# See overview docs at coordinating class, local app/actors/sufia/create_with_files_actor.rb.
class AttachRemoteFileJob < ActiveJob::Base
  # may need to be running on exact same jobs server as further jobs in the stack, like
  # curation_concerns-1.7.8/app/jobs/ingest_file_job.rb:16 :(
  queue_as :ingest

  attr_reader :file_info
  def perform(file_set, file_info, user)
    url = file_info[:url]
    file_name = file_info[:file_name]

    actor = CurationConcerns::Actors::FileSetActor.new(file_set, user)

    # not sure what this URI encoding thing is about, but we're copying from CreateWithRemoteFilesActor
    uri = URI.parse(URI.encode(url))
    if uri.scheme == 'file'
      IngestLocalFileJob.perform_now(file_set, URI.decode(uri.path), user)
    else
      ImportUrlJob.perform_now(file_set, file_name, log(actor.user))
    end
  end

  private

  def log(user)
    CurationConcerns::Operation.create!(user: user,
                                        operation_type: "Attach Remote File")
  end

end
