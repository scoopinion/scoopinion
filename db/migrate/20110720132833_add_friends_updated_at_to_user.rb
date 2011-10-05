class AddFriendsUpdatedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :friends_updated_at, :datetime
  end
end
