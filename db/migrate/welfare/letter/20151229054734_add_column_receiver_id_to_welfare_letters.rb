class AddColumnReceiverIdToWelfareLetters < ActiveRecord::Migration
  def change
    change_column :welfare_letters, :receiver_id, :string
    rename_column :welfare_letters, :receiver_id, :receiver
    add_column :welfare_letters, :star_list, :string
    add_column :welfare_letters, :is_share, :boolean, default: false
    add_column :welfare_letters, :creator_id, :integer
    add_column :welfare_letters, :updater_id, :integer
  end
end
