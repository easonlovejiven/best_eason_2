module Core
  module FeedHelper
    extend ActiveSupport::Concern

    included do
      sorted_set :feeds
      def feeds
        @feeds ||= Feeds.new(self, super)
      end

      Shop::Task.class_eval do
        after_save :update_user_feeds
        # 任务/福利被更新后同时更新用户feed
        def update_user_feeds
          # Redis::Objects.pipelined do |redis|
          #   self.user.followers.each do |user|
          #     key = User.redis_field_key :feeds, user.id
          #     redis.zadd(key, (end_at || Time.now+ 1.month).utc.strftime("%s%L").to_i, self.id)
          #   end
          # end
        end
      end
    end

    # feed 数据逻辑
    # * 发布任务 -> 查找关联明星下的所有粉丝 -> 推送 feed流 并设置feed流的过期时间
    # * 完成任务 -> 该任务从用户 feed流 中删除

    # feed流基本功能
    # * 添加
    # * 自动过期
    # * 删除

    class Feeds < Struct.new(:user, :feeds)
      delegate :redis, to: :user

      def take(limit=9)
        # feeds_ids = feeds.revrange(0,limit).join(',')
        # Shop::Task.active.where(id: with_check { feeds.revrange(0,limit) }).order("FIELD(id,#{feeds_ids})")
        # Shop::Task.is_top.expired.populars.limit(3) + Shop::Task.untop.expired.where(id: with_check { feeds.revrange(0,-1) }).populars.limit(limit-3)
        # Shop::Task.active.expired.where(id: with_check { feeds.revrange(0,-1) }).populars.limit(limit)
        tasks = Shop::Task.expired.published.where(id: with_check { feeds.revrange(0,-1) }).tops.limit(limit)
        if tasks.size < 5
          Shop::Task.where(id: (tasks + Shop::Task.expired.published.where.not(id: tasks.map(&:id)).populars.limit(limit-tasks.count)).map(&:id))
        else
          tasks
        end
        # Shop::Task.published.where(id: with_check { feeds.revrange(0,-1) }).tops.limit(limit)
      end

      def change
        tasks = Shop::Task.expired.published.where(id: with_check { feeds.revrange(0,-1) }).tops
        if tasks.size < 5
          Shop::Task.where(id: (tasks + Shop::Task.expired.published.where.not(id: tasks.map(&:id)).populars.limit(5-tasks.count)).map(&:id))
        else
          tasks
        end
        # Shop::Task.published.where(id: with_check { feeds.revrange(0,-1) }).tops.limit(40)
      end

      def all
        # feeds_ids = feeds.revrange(0,-1).join(',')
        # with_check { Shop::Task.active.where(id: feeds.revrange(0,-1)) }.order("FIELD(id,#{feeds_ids})")
        # Shop::Task.active.expired.where(id: with_check { feeds.revrange(0,-1) }).populars
        # Shop::Task.is_top.expired.populars.limit(3) + Shop::Task.untop.expired.where(id: with_check { feeds.revrange(0,-1) }).populars
        # tasks = Shop::Task.expired.published.where(id: with_check { feeds.revrange(0,-1) }).tops
        # ids = Shop::Task.is_top.expired.published.populars.limit(3).pluck(:id) + Shop::Task.untop.published.expired.where(id: with_check { feeds.revrange(0,-1) }).newests.pluck(:id)
        # if ids.blank?
        #   []
        # else
        #   Shop::Task.published.where(id: ids).order("field(id, #{ids.join(',')})")
        # end

         Shop::Task.expired.published.where(id: with_check { feeds.revrange(0,-1) }).tops
      end

      def tasks
        all.where(category: 'task')
      end

      def welfares
        all.where(category: 'welfare')
      end

      # 检查过期 Feed 并删除
      def with_check(&block)
        # redis.pipelined do
          # feeds.remrangebyscore(0, timestamp)
          return yield
        # end
      end

      def timestamp(time=Time.now)
        time.utc.strftime("%s%L").to_i
      end

      def insert(feed_id, time)
        feeds[feed_id] = timestamp(time)
      end
      alias_method :update, :insert

      def remove(feed_id)
        feeds.delete(feed_id)
      end
    end
  end
end
