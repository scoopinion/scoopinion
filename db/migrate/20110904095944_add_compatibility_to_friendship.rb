class AddCompatibilityToFriendship < ActiveRecord::Migration
  def change
    add_column :friendships, :compatibility, :float
    add_column :friendships, :compatibility_updated_at, :datetime
  end
end
