class AddPicKeyToWelfareVoices < ActiveRecord::Migration
  def change
    add_column :welfare_voices, :pic_key, :string
    add_column :welfare_voices, :duration, :integer
  end
end
