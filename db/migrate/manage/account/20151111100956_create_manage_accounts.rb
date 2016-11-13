class CreateManageAccounts < ActiveRecord::Migration
  def change
    create_table :manage_accounts do |t|
      t.string :email
      t.string :phone
      t.string :crypted_password
      t.string :salt
      t.string :remember_token
      t.string :remember_token_expires_at
      t.string :source
      t.datetime :destroyed_at
      t.string :ip_address
      t.string :client
      t.string :last_login_on
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0

      t.timestamps null: false
    end
  end
end
