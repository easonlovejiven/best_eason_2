class AddColumnClientAndVerifiedToCoreMobileCode < ActiveRecord::Migration
  def change
    add_column :core_mobile_codes, :client, :string, default: "mobile"
    add_column :core_mobile_codes, :verified, :boolean, default: false
  end
end
