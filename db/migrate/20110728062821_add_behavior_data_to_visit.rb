class AddBehaviorDataToVisit < ActiveRecord::Migration
  def change
    add_column :visits, :link_click, :integer
    add_column :visits, :right_click, :integer
    add_column :visits, :mouse_move, :integer
    add_column :visits, :link_hover, :integer
    add_column :visits, :arrow_up, :integer
    add_column :visits, :arrow_down, :integer
    add_column :visits, :scroll_down, :integer
    add_column :visits, :scroll_up, :integer
  end
end
