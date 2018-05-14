class FixityController < ApplicationController
  include Sufia::Breadcrumbs
  require 'date'

  layout 'chf'
  def index
    build_breadcrumbs

    # Don't display successful checks.
    #number_of_checks_to_show = 5
    #@the_latest_checks = ChecksumAuditLog.latest_checks[0..number_of_checks_to_show - 1]

    @how_many_days_back_to_look = 7
    @x_days_ago = (Date.today - @how_many_days_back_to_look).iso8601
    @recent_checksum_count = ChecksumAuditLog.where( "created_at > '#{@x_days_ago}'").count
    @most_recent_check_date = ChecksumAuditLog.order('created_at DESC').first.created_at

    #oldest_check = ChecksumAuditLog.latest_checks.order("created_at desc").first.created_at
    @failed_checks = ChecksumAuditLog.where( passed: false)
    @no_failed_checks = (@failed_checks.count == 0)

    # I would also put a count of the total number of unique files with checks on file.
    # And the total number of files in the repo.
    # Approximately how long does it take for the fixity checks to cycle through all the files in the repo once?

  end
end