class CreateUserLanguages < ActiveRecord::Migration
  def change
    create_table :user_languages do |t|
      t.integer :user_id
      t.string :language

      t.timestamps
    end
  end
end
