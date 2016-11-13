class Follow < ActiveRecord::Base
  self.table_name = :core_follows
  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes
  include Core::FollowAble

  scope :followers_scope_by_user_id, ->(id) { where(followable_id: id, followable_type: 'Core::Star', blocked: 0) }

  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, :polymorphic => true
  belongs_to :follower,   :polymorphic => true
  belongs_to :user, foreign_key: :follower_id, foreign_type: :follower_type, class_name: Core::User
  belongs_to :followable_user, foreign_key: :followable_id, foreign_type: :follower_type, class_name: Core::User

  def block!
    self.update_attribute(:blocked, true)
  end
end
