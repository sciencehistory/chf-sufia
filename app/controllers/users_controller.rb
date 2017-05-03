class UsersController < ApplicationController
  include Sufia::UsersControllerBehavior

  load_and_authorize_resource class: User

  # The Sufia::UsersControllerBehavior method was anemic. Copied from
  # https://github.com/projecthydra/curation_concerns/blob/v1.7.7/app/controllers/concerns/curation_concerns/application_controller_behavior.rb#L23
  # Called when CanCan::AccessDenied is caught
  # @param [CanCan::AccessDenied] exception error to handle
  def deny_access(exception)
    # For the JSON message, we don't want to display the default CanCan messages,
    # just custom Hydra messages such as "This item is under embargo.", etc.
    json_message = exception.message if exception.is_a? Hydra::AccessDenied
    if current_user && current_user.persisted?
      respond_to do |wants|
        wants.html do
          if [:show, :edit, :create, :update, :destroy].include? exception.action
            render 'curation_concerns/base/unauthorized', status: :unauthorized
          else
            redirect_to main_app.root_url, alert: exception.message
          end
        end
        wants.json { render_json_response(response_type: :forbidden, message: json_message) }
      end
    else
      session['user_return_to'.freeze] = request.url
      respond_to do |wants|
        wants.html { redirect_to main_app.new_user_session_path, alert: exception.message }
        wants.json { render_json_response(response_type: :unauthorized, message: json_message) }
      end
    end
  end
end
