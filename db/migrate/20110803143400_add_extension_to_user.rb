class AddExtensionToUser < ActiveRecord::Migration
  def change
    add_column :users, :extension_installed_at, :datetime
  end
end
