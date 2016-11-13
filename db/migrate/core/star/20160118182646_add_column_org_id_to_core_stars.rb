class AddColumnOrgIdToCoreStars < ActiveRecord::Migration
  def change
    add_column :core_stars, :org_id, :integer
  end
end
