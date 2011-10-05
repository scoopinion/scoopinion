class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :url
      t.string :title
      t.integer :visits_count

      t.timestamps
    end
  end
end
