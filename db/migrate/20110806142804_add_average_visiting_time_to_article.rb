class AddAverageVisitingTimeToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :average_visiting_time, :datetime
  end
end
