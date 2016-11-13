class AddColumnClientToCoreLogins < ActiveRecord::Migration
  def change
    add_column :core_logins, :client, :string
  end
end
