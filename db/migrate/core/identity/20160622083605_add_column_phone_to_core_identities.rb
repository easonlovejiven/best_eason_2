class AddColumnPhoneToCoreIdentities < ActiveRecord::Migration
  def change
    add_column :core_identities, :phone, :string
    add_column :core_identities, :position, :string
  end
end
