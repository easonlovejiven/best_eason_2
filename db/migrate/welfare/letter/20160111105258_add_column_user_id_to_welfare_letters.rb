class AddColumnUserIdToWelfareLetters < ActiveRecord::Migration
  def change
    add_column :welfare_letters, :user_id, :integer
  end
end
