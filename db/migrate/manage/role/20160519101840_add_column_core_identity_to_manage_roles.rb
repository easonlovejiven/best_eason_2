class AddColumnCoreIdentityToManageRoles < ActiveRecord::Migration
  def change
    add_column :manage_roles, :core_identity, :integer, default: 0
  end
end
