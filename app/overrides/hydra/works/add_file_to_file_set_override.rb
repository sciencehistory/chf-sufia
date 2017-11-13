# Doing two things in override:

# 1. Override and call super on #call to hook into "do this only after file is
# actually added to fedora", to trigger DZI creation.  Can't find a better way to do that.
#
# https://bibwild.wordpress.com/2017/07/11/on-hooking-into-sufiahyrax-after-file-has-been-uploaded/
#
#
# 2. reindex the fileset after adding a file to it. It's characteristics have changed, so
# may need reindex. Plus, if this fileset is marked representative of a parent work, reindex
# the parent work too.
# In the default stack, create derivatives action triggered these reindexes,
# but that wasn't the right place (sometimes doing unneccesary
# reindexes on bulk deriv creation), this is.
Hydra::Works::AddFileToFileSet.class_eval do

  AddFileToFileSetClassOverrides = Module.new do
    def call(file_set, file, type, update_existing: true, versioning: true)
      # when we implemented, super was in hydra-works 0.16.0.
      # https://github.com/samvera/hydra-works/blob/v0.16.0/lib/hydra/works/services/add_file_to_file_set.rb#L10
      super.tap do
        # reindex the fileset, cause we added things to it, so it needs reindexing.
        file_set.update_index

        # If this file_set is the thumbnail for the parent work,
        # then the parent also needs to be reindexed.
        if file_set.parent && (file_set.parent.thumbnail_id == file_set.id || file_set.parent.representative_id == file_set.id)
          file_set.parent.update_index
        end

        # Trigger DZI creation in bg job
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
