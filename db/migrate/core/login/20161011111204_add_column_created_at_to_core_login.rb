class AddColumnCreatedAtToCoreLogin < ActiveRecord::Migration
  def change
    add_column :core_logins, :created_at, :datetime
  end
end
