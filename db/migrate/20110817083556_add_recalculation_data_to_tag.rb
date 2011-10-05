class AddRecalculationDataToTag < ActiveRecord::Migration
  def change
    add_column :tags, :recalculated_at, :datetime, :default => Time.now
    add_column :tags, :new_data_since_recalculated, :integer, :default => 0
    
    Tag.reset_column_information
    
    Tag.find_each do |t|
      t.recalculated_at = Time.now
      t.new_data_since_recalculated = 0
      t.save
    end
  end
end
