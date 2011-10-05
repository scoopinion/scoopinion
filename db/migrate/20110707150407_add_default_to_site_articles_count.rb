class AddDefaultToSiteArticlesCount < ActiveRecord::Migration
  def change
    change_column :sites, :articles_count, :integer, :default => 0
  end
end
