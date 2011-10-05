class AddFinderIdToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :finder_id, :integer    
  end
end
