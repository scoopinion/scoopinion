class AddIndexToTokenFrequency < ActiveRecord::Migration
  def change
    add_index :token_frequencies, :token_id
  end
end
