class AddKinderDescriptionToShopTopics < ActiveRecord::Migration
  def change
    add_column :shop_topics, :kinder_description, :text
  end
end
