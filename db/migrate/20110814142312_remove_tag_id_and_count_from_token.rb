class RemoveTagIdAndCountFromToken < ActiveRecord::Migration
  def up
    remove_column :tokens, :tag_id
  end

  def down
    add_column :tokens, :tag_id, :integer
  end
end
