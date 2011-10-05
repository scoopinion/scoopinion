class FriendshipsController < ApplicationController

  before_filter :require_user
  
  respond_to :html, :json
  
  def index
    @friendships = current_user.friendships
    respond_with(@friendships) do |format|
      format.json { render :json => @friendships }
      format.html
    end
  end

  def create
    begin
      friend_uids = params[:friends] || []
      successful_friends = 0
      friend_uids.each do |uid|
        @friend = Authentication.find_by_uid(uid)
        if @friend
          @friendship = Friendship.find_or_initialize_by_user_id_and_friend_id(current_user.id, @friend.user_id)
          successful_friends += 1 unless  @friendship.persisted?
          @friendship.save
          @inverse_friendship = Friendship.find_or_create_by_user_id_and_friend_id(@friend.user_id, current_user.id)
          current_user.touch(:friends_updated_at)
        end
      end
    render :text => successful_friends
    end
  end
end
