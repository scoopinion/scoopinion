class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :login,               :null => false
      t.string :email,               :null => false
      t.string :crypted_password,    :null => false
      t.string :password_salt,       :null => false
      t.string :persistence_token,   :null => false
      t.string :single_access_token, :null => false                # optional, see Authlogic::Session::Params
      
      t.timestamps
    end
  end
end
