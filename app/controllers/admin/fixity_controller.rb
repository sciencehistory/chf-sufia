module Admin
  class FixityController < ApplicationController
    include Sufia::Breadcrumbs
    require 'date'
    layout 'admin'
    def index
      authorize! :read, :admin_dashboard
      add_breadcrumb t(:'sufia.controls.home'), root_path
      add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
      add_breadcrumb 'Fixity checks', admin_fixity_index_path

      @how_many_days_back_to_look = 7
      @x_days_ago = (Date.today - @how_many_days_back_to_look).iso8601
      @recent_checksum_count = ChecksumAuditLog.where( "created_at > '#{@x_days_ago}'").count


      @most_recent_check_date = ChecksumAuditLog.latest_checks.order('created_at').first.created_at

      # Note: old audit logs are kept when FileSets are deleted from the repo, which leads to unexpected results here.
      # We may want to amend the prune_history functionality so that when a
      # FileSet is deleted, all ChecksumAuditLogs associated with it are removed.
      @oldest_check_date      = ChecksumAuditLog.latest_checks.order('created_at').last.created_at


      # Count of the total number of unique files with checks on file
      @unique_checked_files_count = ChecksumAuditLog.select(:file_set_id).distinct.count


      # Are there any files that have *not* been checked? (commented out for now, as this is too slow to be practical.)

      # all_fileset_ids = FileSet.all.map{|fs| fs.id}
      # all_checked_filset_ids = ChecksumAuditLog.select(:file_set_id).distinct.map{|fs| fs.file_set_id}
      # unchecked_fileset_ids = (all_fileset_ids -  all_checked_filset_ids)


      # Total number of FileSets in the repo:
      @total_files = FileSet.count
      @failed_checks = ChecksumAuditLog.where( passed: false)
      @no_failed_checks = (@failed_checks.count == 0)
    end
  end
end