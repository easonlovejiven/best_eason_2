class CreateCoreConnections < ActiveRecord::Migration
  def change
    create_table :core_connections do |t|
    	t.integer  :account_id
    	t.string   :site, null: false
    	t.text     :token
    	t.text     :secret
    	t.text     :refresh_token
    	t.datetime :expired_at
    	t.text     :data
	    t.string   :identifier
  	  t.string   :email
    	t.string   :name
    	t.string   :sex
    	t.string   :pic
    	t.string   :phone
    	t.boolean  :active, default: true, null: false
      t.timestamps null: false
    end
    add_index :core_connections, [:account_id, :site], name: "by_account_id_and_site"
    add_index :core_connections, [:active, :account_id], name: "by_active_and_account_id"
 	 	add_index :core_connections, [:active, :site, :identifier], name: "by_active_and_site_and_identifier"
  end
end
