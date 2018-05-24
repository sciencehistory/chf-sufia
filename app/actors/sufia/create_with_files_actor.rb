# Overridden from Sufia to do the job of CreateWithFilesActor _and_ CreateWithRemoteFilesActor,
# from sufia 7.4.0.
#
# https://github.com/samvera/sufia/blob/v7.4.0/app/actors/sufia/create_with_files_actor.rb
# https://github.com/samvera/sufia/blob/v7.4.0/app/actors/sufia/create_with_remote_files_actor.rb
#
# Becuase:
# * CreateWithRemoteFilesActor was doing things it didn't need to in the foreground, making it take
#   too long for submit to return.
#
# If we have to hack into it, makes it simpler to unify into one actor and set of jobs, instead of parallel
# ones. Make what's going on more sane, so we have a better chance of reasoning about it and debugging it.
module Sufia
  # Creates a work and attaches files to the work
  class CreateWithFilesActor < CurationConcerns::Actors::AbstractActor
    attr_accessor :remote_files

    def create(attributes)
      self.uploaded_file_ids = attributes.delete(:uploaded_files)
      self.remote_files = attributes.delete(:remote_files)

      validate_local_files && next_actor.create(attributes) && attach_local_files && attach_remote_files
    end

    def update(attributes)
      self.uploaded_file_ids = attributes.delete(:uploaded_files)
      self.remote_files = attributes.delete(:remote_files)

      validate_local_files && next_actor.update(attributes) && attach_local_files && attach_remote_files
    end

    protected

      attr_reader :uploaded_file_ids
      def uploaded_file_ids=(input)
        @uploaded_file_ids = Array.wrap(input).select(&:present?)
      end

      # ensure that the files we are given are owned by the depositor of the work
      def validate_local_files
        expected_user_id = user.id
        uploaded_files.each do |file|
          if file.user_id != expected_user_id
            Rails.logger.error "User #{user.user_key} attempted to ingest uploaded_file #{file.id}, but it belongs to a different user"
            return false
          end
        end
        true
      end

      # @return [TrueClass]
      def attach_local_files
        uploaded_files.each do |uploaded_file|
          AttachLocalFileJob.perform_later(curation_concern, uploaded_file, user)
        end
        true
      end

      # Taken from CreateWithRemoteFilesActor#attach_files, but some logic moved into
      # our custom per-file job.
      def attach_remote_files
        remote_files.each do |file_info|
          next if file_info.blank? || file_info[:url].blank?
          AttachRemoteFileJob.perform_later(curation_concern, file_info, user)
        end
        true
      end



      # Fetch uploaded_files from the database
      def uploaded_files
        return [] if uploaded_file_ids.empty?
        @uploaded_files ||= UploadedFile.find(uploaded_file_ids)
      end
  end
end
