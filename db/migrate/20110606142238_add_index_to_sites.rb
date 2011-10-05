class AddIndexToSites < ActiveRecord::Migration
  def change
    add_index :sites, :url
  end
end
