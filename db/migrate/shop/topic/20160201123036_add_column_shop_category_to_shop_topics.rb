class AddColumnShopCategoryToShopTopics < ActiveRecord::Migration
  def change
    add_column :shop_topics, :shop_category, :string, default: 'shop_topics'
  end
end
