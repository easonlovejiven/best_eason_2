class AddGudieToShopTopics < ActiveRecord::Migration
  def change
    add_column :shop_topics, :guide, :string
  end
end
