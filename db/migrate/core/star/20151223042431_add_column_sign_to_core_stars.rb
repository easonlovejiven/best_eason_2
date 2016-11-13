class AddColumnSignToCoreStars < ActiveRecord::Migration
  def change
    add_column :core_stars, :sign, :string
    add_column :core_stars, :nickname, :string
    add_column :core_stars, :cover, :string
  end
end
