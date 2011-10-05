class UpdateArticleCountForAllSites < ActiveRecord::Migration
  def up
    Site.reset_column_information
    Site.find_each do |s|
      Site.reset_counters s.id, :articles
    end
  end

  def down
  end
end
