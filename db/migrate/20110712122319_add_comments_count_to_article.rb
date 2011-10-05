class AddCommentsCountToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :comments_count, :integer
    Article.reset_column_information
    Article.find_each do |s|
      Article.reset_counters s.id, :comments
    end
  end
end
