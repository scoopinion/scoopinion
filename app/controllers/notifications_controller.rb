class NotificationsController < ApplicationController

  def update
    @notification = Notification.find_by_id(params[:id])
    @notification.update_attributes(params[:notification])
    head :ok
  end

end
