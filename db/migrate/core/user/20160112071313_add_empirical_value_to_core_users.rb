class AddEmpiricalValueToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :empirical_value, :integer, default: 0
    add_column :core_users, :obi, :integer, default: 0
  end
end
