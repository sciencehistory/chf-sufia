# Override and call super on #call to hook into "do this only after file is
# actually added to fedora" Can't find a better way to do that.
#
# https://bibwild.wordpress.com/2017/07/11/on-hooking-into-sufiahyrax-after-file-has-been-uploaded/
#
Hydra::Works::AddFileToFileSet.class_eval do

  AddFileToFileSetClassOverrides = Module.new do
    def call(file_set, file, type, update_existing: true, versioning: true)
      # super at hydra-works 0.16.0 when implemented.
      # https://github.com/samvera/hydra-works/blob/v0.16.0/lib/hydra/works/services/add_file_to_file_set.rb#L10
      super.tap do
        # Got here without an error? Trigger DZI creation
        if CHF::Env.lookup(:dzi_auto_create)
          CreateDziJob.perform_later(file_set.id, repo_file_type: type.to_s)
        end
      end
    end
  end

  # Cause we want to prepend a CLASS method, we do it on singleton_class
  unless self.singleton_class.include?(AddFileToFileSetClassOverrides)
    self.singleton_class.prepend AddFileToFileSetClassOverrides
  end
end
