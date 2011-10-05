class AddSupertagIdToTag < ActiveRecord::Migration
  def change
    add_column :tags, :supertag_id, :integer
  end
end
