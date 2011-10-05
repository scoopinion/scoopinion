class ChangeVisitReferrerToText < ActiveRecord::Migration
  def up
    change_column :visits, :referrer, :text
  end

  def down
  end
end
