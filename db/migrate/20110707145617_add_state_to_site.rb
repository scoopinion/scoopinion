class AddStateToSite < ActiveRecord::Migration
  def change
    add_column :sites, :state, :string
  end
end
