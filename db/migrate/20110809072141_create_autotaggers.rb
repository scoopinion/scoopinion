class CreateAutotaggers < ActiveRecord::Migration
  def change
    create_table :autotaggers do |t|
      t.string :condition
      t.string :tag

      t.timestamps
    end
  end
end
