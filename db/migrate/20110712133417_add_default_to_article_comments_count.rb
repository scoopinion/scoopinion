class AddDefaultToArticleCommentsCount < ActiveRecord::Migration
  def change
    change_column :articles, :comments_count, :integer, :default => 0
  end
end
