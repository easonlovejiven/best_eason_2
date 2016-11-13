class AddCreatorIdToShopTopics < ActiveRecord::Migration
  def change
    add_column :shop_topics, :creator_id, :integer
    add_column :shop_topics, :star_list, :string
  end
end
