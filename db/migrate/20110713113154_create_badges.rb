class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.integer :user_id
      t.string :badge_type
      t.integer :level

      t.timestamps
    end
  end
end
