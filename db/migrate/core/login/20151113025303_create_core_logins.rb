class CreateCoreLogins < ActiveRecord::Migration
  def change
    create_table :core_logins do |t|
    	t.integer :user_id
    	t.date :login_on
    	t.string  :ip_address, limit: 20
    end
    add_index :core_logins, [:user_id, :login_on], name: "index_core_logins_on_user_id_and_login_on"
  end
end
