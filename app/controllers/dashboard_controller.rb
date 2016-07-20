class DashboardController < ApplicationController
  include Sufia::DashboardControllerBehavior

  protected

    # Gathers all the information that we'll display in the user's dashboard.
    # Override this method if you want to exclude or gather additional data elements
    # in your dashboard view.  You'll need to alter dashboard/index.html.erb accordingly.
    def gather_dashboard_information
      @user = current_user
      @activity = current_user.all_user_activity(params[:since].blank? ? DateTime.now.to_i - Sufia.config.activity_to_show_default_seconds_since_now : params[:since].to_i)
      @notifications = current_user.mailbox.inbox
      # CHF edit 2016-06-22 only show transfer requests that are pending
      @incoming = ProxyDepositRequest.where(receiving_user_id: current_user.id).where(status: 'pending').reject(&:deleted_work?)
      @outgoing = ProxyDepositRequest.where(sending_user_id: current_user.id).where(status: 'pending')
    end

end
