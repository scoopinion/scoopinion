class AddScheduledToFriendship < ActiveRecord::Migration
  def change
    add_column :friendships, :recalculation_scheduled, :boolean
  end
end
