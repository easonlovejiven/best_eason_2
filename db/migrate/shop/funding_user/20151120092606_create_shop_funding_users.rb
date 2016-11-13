class CreateShopFundingUsers < ActiveRecord::Migration
  def change
    create_table :shop_funding_users do |t|
      t.belongs_to :shop_funding
      t.belongs_to :core_user

      t.timestamps null: false
    end
  end
end
