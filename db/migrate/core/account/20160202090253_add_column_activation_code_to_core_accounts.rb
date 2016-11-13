class AddColumnActivationCodeToCoreAccounts < ActiveRecord::Migration
  def change
    add_column :core_accounts, :activation_code, :string
    add_column :core_accounts, :activated_at, :datetime
  end
end
