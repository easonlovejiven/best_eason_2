class AddColumnsCategoryToCoreStars < ActiveRecord::Migration
  def change
    add_column :core_stars, :category, :integer, default: 0
  end
end
