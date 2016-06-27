class TransfersController < ApplicationController
  include Sufia::TransfersControllerBehavior

  # chf edit 2016-06-27 it takes too long to load the full page of all transfers after doing this stuff.
  # note redirect_to :back will be deprecated in rails 5 http://stackoverflow.com/a/36144363
  def accept
    @proxy_deposit_request.transfer!(params[:reset])
    if params[:sticky]
      current_user.can_receive_deposits_from << @proxy_deposit_request.sending_user
    end
    redirect_to :back, notice: "Transfer complete"
  end

  def reject
    @proxy_deposit_request.reject!
    redirect_to :back, notice: "Transfer rejected"
  end

  def destroy
    @proxy_deposit_request.cancel!
    redirect_to :back, notice: "Transfer canceled"
  end

end
