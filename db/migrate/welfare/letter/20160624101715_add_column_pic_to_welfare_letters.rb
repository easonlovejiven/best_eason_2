class AddColumnPicToWelfareLetters < ActiveRecord::Migration
  def change
    add_column :welfare_letters, :pic, :string
  end
end
