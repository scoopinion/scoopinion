class AddLanguageToSite < ActiveRecord::Migration
  def change
    add_column :sites, :language, :string
  end
end
