class AddColumnAddressIdAndAddressToCoreExpens < ActiveRecord::Migration
  def change
    add_column :core_expens, :address, :text
    add_column :core_expens, :address_id, :integer
  end
end
