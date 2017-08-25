# Override https://github.com/samvera/sufia/blob/v7.3.0/app/uploaders/sufia/uploaded_file_uploader.rb#L19
# as per bug fix https://github.com/samvera/hyrax/commit/6ca1f779fe08311986c6a34fc3eecadbf0ed7f28
# This can be removed upon upgrade to hyrax.

if Gem.loaded_specs["hyrax"]
  msg = "\n\nPlease remove patch to method n ames in file uploader at #{__FILE__}:#{__LINE__}\n\n"
  $stderr.puts msg
  Rails.logger.warn msg
end


Sufia::UploadedFileUploader.class_eval do
  def cache_dir
    configured_cache_path + "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  private

    def configured_cache_path
      Sufia.config.cache_path.call
    end
end
