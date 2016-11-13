class RenameDefaultToCoreAddresses < ActiveRecord::Migration
  def change
    rename_column :core_addresses, :default, :is_default
  end
end
