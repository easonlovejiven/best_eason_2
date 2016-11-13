class AddCommentToShopTopicDynamics < ActiveRecord::Migration
  def change
    add_column :shop_topic_dynamics, :comment_count, :integer, default: 0
    add_column :shop_topic_dynamics, :like_count, :integer, default: 0
    add_column :shop_topic_dynamics, :foward_count, :integer, default: 0
  end
end
