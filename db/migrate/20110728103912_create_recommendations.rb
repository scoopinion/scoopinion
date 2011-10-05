class CreateRecommendations < ActiveRecord::Migration
  def change
    create_table :recommendations do |t|
      t.integer :user_id
      t.integer :article_id
      t.string :state

      t.timestamps
    end
  end
end
