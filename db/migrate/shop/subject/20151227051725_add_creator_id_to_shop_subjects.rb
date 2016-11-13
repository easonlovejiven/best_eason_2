class AddCreatorIdToShopSubjects < ActiveRecord::Migration
  def change
    add_column :shop_subjects, :updater_id, :integer
  end
end
