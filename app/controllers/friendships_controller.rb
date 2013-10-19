class FriendshipsController < ApplicationController

  before_filter :require_user
  
  respond_to :html, :json

  def update
    if params[:uid]
      begin
        friend = Authentication.find_by_uid(params[:uid]).user
        friendship = Friendship.find(:first, :conditions => {:user_id => current_user.id, :friend_id => friend.id})
        friendship.invited = true
        friendship.save
        render :status => :ok
      rescue
        render :text => "Friendship not found"
      end
    else
      render :text => "Please provide uid"
    end
  end

end
