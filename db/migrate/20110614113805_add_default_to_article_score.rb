class AddDefaultToArticleScore < ActiveRecord::Migration
  def change
    change_column :articles, :score, :integer, :default => 0
  end
end
