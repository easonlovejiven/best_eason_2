class AddColumnloginSaltToCoreAccounts < ActiveRecord::Migration
  def change
    add_column :core_accounts, :login_salt, :string
  end
end
