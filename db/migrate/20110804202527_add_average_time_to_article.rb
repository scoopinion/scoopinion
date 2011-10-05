class AddAverageTimeToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :average_time, :integer
  end
end
