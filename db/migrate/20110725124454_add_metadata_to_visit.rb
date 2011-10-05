class AddMetadataToVisit < ActiveRecord::Migration
  def change
    add_column :visits, :total_time, :integer
    add_column :visits, :total_scrolled, :integer
  end
end
