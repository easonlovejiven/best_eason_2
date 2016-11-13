class AddColumnDeviceIdToCoreLogin < ActiveRecord::Migration
  def change
    add_column :core_logins, :device_id, :string
    add_column :core_logins, :device_models, :string
    add_column :core_logins, :manufacturer, :string
    add_column :core_logins, :system_version, :string
    add_column :core_logins, :user_agent, :text
  end
end
