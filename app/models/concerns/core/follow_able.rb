module Core::FollowAble
  extend ActiveSupport::Concern

  included do
    after_commit on: :create do
      FollowWorker.perform_async(id, 'follow')
    end

    before_destroy do
      # FollowWorker.perform_async(self, 'unfollow')
      followable.shop_tasks.expired.published.find_each do |feed|
        follower.feeds.remove(feed.id)
      end
    end

    def create_user_feeds
      Redis::Objects.redis.pipelined do |redis|
        followable.shop_tasks.expired.published.find_each do |feed|
          follower.feeds.insert(feed.id, Time.now)
        end
      end
    end

    def destroy_user_feeds
      Redis::Objects.redis.pipelined do |redis|
        followable.shop_tasks.active.find_each do |feed|
          follower.feeds.remove(feed.id)
        end
      end
    end
  end
end
