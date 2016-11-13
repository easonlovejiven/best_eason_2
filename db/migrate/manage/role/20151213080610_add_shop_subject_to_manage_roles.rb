class AddShopSubjectToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :shop_subject, :integer, default: 0
  end
end
