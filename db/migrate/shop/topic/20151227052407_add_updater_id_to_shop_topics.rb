class AddUpdaterIdToShopTopics < ActiveRecord::Migration
  def change
    add_column :shop_topics, :updater_id, :integer
  end
end
