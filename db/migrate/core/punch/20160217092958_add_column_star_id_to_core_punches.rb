class AddColumnStarIdToCorePunches < ActiveRecord::Migration
  def change
    add_column :core_punches, :star_id, :integer
  end
end
