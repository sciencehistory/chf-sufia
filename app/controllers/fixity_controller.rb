class FixityController < ApplicationController
  include Sufia::Breadcrumbs
  require 'date'
  layout 'admin'
  def index
    authorize! :read, :admin_dashboard
    add_breadcrumb t(:'sufia.controls.home'), root_path
    add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
    add_breadcrumb 'Fixity checks', 'fixity'
    @how_many_days_back_to_look = 7
    @x_days_ago = (Date.today - @how_many_days_back_to_look).iso8601
    @recent_checksum_count = ChecksumAuditLog.where( "created_at > '#{@x_days_ago}'").count
    @most_recent_check_date = ChecksumAuditLog.latest_checks.order('created_at DESC').first.created_at
    @oldest_check_date = ChecksumAuditLog.latest_checks.order("c2.created_at").last.created_at
    # Count of the total number of unique files with checks on file
    @unique_checked_files_count = ChecksumAuditLog.select(:file_id).distinct.count
    # Total number of files in the repo:
    @total_files = FileSet.count
    @failed_checks = ChecksumAuditLog.where( passed: false)
    @no_failed_checks = (@failed_checks.count == 0)
  end
end