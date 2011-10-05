class AddSiteIdToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :site_id, :integer
  end
end
