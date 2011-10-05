class AddParameterToTag < ActiveRecord::Migration
  def change
    add_column :tags, :parameter, :string
    Tag.reset_column_information
    Tag.all.each{ |t| t.parameter = t.to_param; t.save }
  end
end
