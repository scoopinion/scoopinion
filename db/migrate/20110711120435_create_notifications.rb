class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.integer :reason_id
      t.string :reason_type
      t.string :state, :default => "new"

      t.timestamps
    end
  end
end
