class CreateTagPredictions < ActiveRecord::Migration
  def change
    create_table :tag_predictions do |t|
      t.integer :tag_id
      t.integer :article_id
      t.float :confidence
      t.string :state

      t.timestamps
    end
  end
end
