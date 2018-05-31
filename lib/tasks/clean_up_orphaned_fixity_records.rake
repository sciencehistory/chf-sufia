# Context:
# When a fileset is deleted from Fedora, the records for its fixity checks remain in the database.
# This creates confusion when attempting to ensure that all current files have had their fixity
# checked recently.
#
# This job loops through all fixity records and verified that they are associated with a fileset that we
# still have on hand. If it turns out they are not, we delete the "orphaned" fixity check record.

namespace :chf do
  desc "run fixity checks with logs and notification on failure"
  task :clean_up_orphaned_fixity_checks => :environment do
    @conn = Blacklight.default_index.connection
    x = 0
    n = 100
    loop do
      batch = ChecksumAuditLog.select(:file_set_id).distinct[x..x+n-1]
      if batch == nil
        break
      end
      # This next line is cheap (just looks at 100 solr records at a time)
      #and most of the time returns an empty array.
      missing =  items_missing_in_solr(batch.map{|a| a.file_set_id})
      missing.each do |m|
        # Oh no! One of the logs refers to something that's not in SOLR.
        # If it's not in Fedora, get rid of it.
        delete_unless_exists_in_fedora(m)
      end
      x = x + n
    end #loop
  end #task
end

# Make sure these FileSets are actually in solr.
# Each function call makes one hit to SOLR (even if you pass it a hundred ids.)
# If any of these filesets are not in SOLR, return their IDs.
def items_missing_in_solr(list_of_file_set_ids)
  ids_string = list_of_file_set_ids.join(",")
  response = @conn.get('get', params: {:ids => ids_string  , :fl => 'id' })
  puts response
  if list_of_file_set_ids.count == response['response']['docs'].count
    []
  else
    ids_returned = response['response']['docs'].collect{ |x| x['id'] }
    list_of_file_set_ids - ids_returned
  end
end

# Make sure this file_set is in Fedora before deleting its fixity checks
def item_in_fedora(file_set_id)
  begin
    FileSet.exists?(:id => file_set_id)
  rescue Ldp::Gone
    false
  end
end

def delete_unless_exists_in_fedora(file_set_id)
  if !item_in_fedora(file_set_id)
    ChecksumAuditLog.where(:file_set_id => file_set_id).find_each(&:destroy)
  end
end