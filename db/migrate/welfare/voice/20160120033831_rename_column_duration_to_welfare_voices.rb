class RenameColumnDurationToWelfareVoices < ActiveRecord::Migration
  def change
    change_column :welfare_voices, :duration, :string
  end
end
