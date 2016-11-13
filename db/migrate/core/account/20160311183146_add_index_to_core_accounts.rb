class AddIndexToCoreAccounts < ActiveRecord::Migration
  def change
    add_index :core_accounts, [:phone, :active], name: 'by_phone_and_active'
    add_index :core_accounts, [:email, :active], name: 'by_email_and_active'
    add_index :core_users, [:name, :active], name: 'by_name_and_active'
    add_index :shop_carts, [:uid], name: 'by_uid'
    add_index :core_users, [:old_uid, :active], name: 'by_old_uid_actibe'
    add_index :core_users, [:identity, :participants, :position, :active], name: 'by_identity_actibe'
  end
end
