class AddScoreToVisit < ActiveRecord::Migration
  def change
    add_column :visits, :score, :integer
  end
end
