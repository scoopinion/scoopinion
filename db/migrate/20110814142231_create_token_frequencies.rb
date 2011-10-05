class CreateTokenFrequencies < ActiveRecord::Migration
  def change
    create_table :token_frequencies do |t|
      t.integer :token_id
      t.integer :tag_id
      t.integer :count

      t.timestamps
    end
  end
end
