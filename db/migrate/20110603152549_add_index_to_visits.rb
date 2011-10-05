class AddIndexToVisits < ActiveRecord::Migration
  def change
    add_index :visits, [ :article_id, :user_id ]
  end
end
