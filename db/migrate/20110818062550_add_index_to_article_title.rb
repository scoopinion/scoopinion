class AddIndexToArticleTitle < ActiveRecord::Migration
  def change
    add_index :articles, :url
    add_index :articles, [ :title, :site_id ]
  end
end
