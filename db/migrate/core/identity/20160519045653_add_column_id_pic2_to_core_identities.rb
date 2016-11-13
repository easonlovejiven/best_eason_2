class AddColumnIdPic2ToCoreIdentities < ActiveRecord::Migration
  def change
    add_column :core_identities, :id_pic2, :string
    add_column :core_identities, :updater_id, :integer
    add_column :core_identities, :creator_id, :integer
    change_column :core_identities, :status, :integer, default: 0
  end
end
