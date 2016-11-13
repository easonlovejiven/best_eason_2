class AddCativeToWelfareVoices < ActiveRecord::Migration
  def change
    add_column :welfare_voices, :active, :boolean, default: true
  end
end
