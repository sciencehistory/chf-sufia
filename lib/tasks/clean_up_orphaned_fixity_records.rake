# Context:
# When a fileset is deleted from Fedora, the records for its fixity checks remain in the database.
# This creates confusion when attempting to ensure that all current files have had their fixity
# checked recently.
#
# What this job does:
# Loop through all fixity records and verify that they are associated with a fileset that we
# still have on hand. If it turns out they are not, delete the "orphaned" fixity check record.

namespace :chf do
  desc "run fixity checks with logs and notification on failure"
  task :clean_up_orphaned_fixity_checks => :environment do
    @conn = Blacklight.default_index.connection
    ChecksumAuditLog.find_in_batches(batch_size: 100) do | batch |
      # This next line is cheap (just looks at 100 solr records at a time)
      # and most of the time returns an empty array.
      missing = items_missing_from_solr(batch.map(&:file_set_id))
      # If any ChecksumAuditLog refer to filesets that are not recognized by
      # SOLR, check Fedora to ensure that the fileset has really been deleted.
      # If the fileset has been deleted from Fedora, then go ahead and remove the
      # ChecksumAuditLog that refers to it.
      missing.map!(&:delete_unless_exists_in_fedora)
    end # find in batches
  end #task
end

# Make sure these FileSets are actually in solr.
# Each function call hits SOLR once (even if you pass it a hundred ids.)
# If any of these filesets are not in SOLR, return their IDs.
# Most of the time, this should return an empty array.
def items_missing_from_solr(list_of_file_set_ids)
  ids_string = list_of_file_set_ids.join(",")
  response = @conn.get('get', params: {:ids => ids_string  , :fl => 'id' })
  if list_of_file_set_ids.count == response['response']['docs'].count
    []
  else
    ids_returned = response['response']['docs'].collect{ |x| x['id'] }
    list_of_file_set_ids - ids_returned
  end
end

def item_exists_in_fedora?(file_set_id)
  begin
    FileSet.exists?(:id => file_set_id)
  rescue Ldp::Gone
    false
  end
end

# It's OK to call this on the same file_set_id twice in a row;
# it won't fail if the ChecksumAuditLog has already been destroyed.
def delete_unless_exists_in_fedora(file_set_id)
  if !item_exists_in_fedora?(file_set_id)
    ChecksumAuditLog.where(:file_set_id => file_set_id).find_each(&:destroy)
  end
end