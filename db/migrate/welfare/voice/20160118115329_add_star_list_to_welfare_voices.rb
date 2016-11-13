class AddStarListToWelfareVoices < ActiveRecord::Migration
  def change
    add_column :welfare_voices, :title, :string
    add_column :welfare_voices, :star_list, :string
  end
end
