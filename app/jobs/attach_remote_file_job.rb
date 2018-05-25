# Take a single "remote" file (via browse_everything), and create a fileset, and attach
# it to the work. An extraction of CreateWithRemoteFilesActor, to be on a single file, in
# it's own job, and not launch any other jobs, called by our custom CreateWithFilesActor.
#
# https://github.com/samvera/sufia/blob/v7.4.0/app/actors/sufia/create_with_remote_files_actor.rb
#
# See overview docs at coordinating class, local app/actors/sufia/create_with_files_actor.rb.
class AttachRemoteFileJob < ActiveJob::Base
  queue_as :jobs_server

  attr_reader :file_info
  def perform(work, file_info, user)
    url = file_info[:url]
    file_name = file_info[:file_name]

    user = User.find_by_user_key(work.depositor)

    ::FileSet.new(import_url: url, label: file_name) do |fs|
      actor = CurationConcerns::Actors::FileSetActor.new(fs, user)
      actor.create_metadata(work, visibility: work.visibility)
      fs.save!

      # not sure what this URI encoding thing is about, but we're copying from CreateWithRemoteFilesActor
      uri = URI.parse(URI.encode(url))
      if uri.scheme == 'file'
        IngestLocalFileJob.perform_now(fs, URI.decode(uri.path), user)
      else
        ImportUrlJob.perform_now(fs, file_name, log(actor.user))
      end
    end
  end

  private

  def log(user)
    CurationConcerns::Operation.create!(user: user,
                                        operation_type: "Attach Remote File")
  end

end
