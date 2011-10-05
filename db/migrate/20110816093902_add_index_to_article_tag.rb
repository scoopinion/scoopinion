class AddIndexToArticleTag < ActiveRecord::Migration
  def change
    add_index :article_tags, :article_id
  end
end
