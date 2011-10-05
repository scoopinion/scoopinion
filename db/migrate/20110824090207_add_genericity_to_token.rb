class AddGenericityToToken < ActiveRecord::Migration
  def change
    add_column :tokens, :genericity, :float
  end
end
