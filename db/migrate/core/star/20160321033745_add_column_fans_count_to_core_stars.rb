class AddColumnFansCountToCoreStars < ActiveRecord::Migration
  def change
    add_column :core_stars, :fans_count, :integer, default: 0
  end
end
