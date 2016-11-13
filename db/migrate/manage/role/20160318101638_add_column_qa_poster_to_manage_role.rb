class AddColumnQaPosterToManageRole < ActiveRecord::Migration
  def change
    add_column :manage_roles, :qa_poster, :integer, default: 0
  end
end
