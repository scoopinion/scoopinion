class AddArticlesCountToSite < ActiveRecord::Migration
  def change
    add_column :sites, :articles_count, :integer
  end
end
