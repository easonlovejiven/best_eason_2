class ChangeColumnCountToCoreRecordings < ActiveRecord::Migration
  def change
    change_column :core_recordings, :count, :integer, default: 1
  end
end
