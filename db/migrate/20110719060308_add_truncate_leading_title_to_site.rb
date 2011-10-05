class AddTruncateLeadingTitleToSite < ActiveRecord::Migration
  def change
    add_column :sites, :truncate_leading_title, :boolean, :defaut => false
    Site.reset_column_information
    if Site.find_by_title("BBC")
      Site.find_by_title("BBC").update_attribute :truncate_leading_title, true
    end
  end
end
