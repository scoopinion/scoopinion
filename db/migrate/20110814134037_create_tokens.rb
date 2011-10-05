class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.string :name
      t.integer :tag_id
      t.integer :count

      t.timestamps
    end
    
    add_index :tokens, :name
  end
end
