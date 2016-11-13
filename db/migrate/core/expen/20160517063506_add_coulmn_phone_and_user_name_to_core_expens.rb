class AddCoulmnPhoneAndUserNameToCoreExpens < ActiveRecord::Migration
  def change
    add_column :core_expens, :phone, :string
    add_column :core_expens, :user_name, :string
  end
end
