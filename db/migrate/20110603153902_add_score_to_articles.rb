class AddScoreToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :score, :integer
    Article.reset_column_information
    Article.all.each do |a|
      a.score = a.visits.sum(:score)
      puts a.score
      a.save
    end
  end
end
