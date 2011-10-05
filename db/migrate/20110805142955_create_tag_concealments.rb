class CreateTagConcealments < ActiveRecord::Migration
  def change
    create_table :tag_concealments do |t|
      t.integer :user_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
