class AddKeyToShopTopics < ActiveRecord::Migration
  def change
    add_column :shop_topics, :key, :string
  end
end
