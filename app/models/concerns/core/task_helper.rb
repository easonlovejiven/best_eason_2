module Core
  module TaskHelper
    extend ActiveSupport::Concern

    included do
      # after_update do
      #   if self.is_top_changed? && self.is_top
      #     TaskWorker.perform_async(id, 'top')
      #   end
      # end

      # after_create do
      #   TaskWorker.perform_async(id, 'create', (JSON.parse(star_list.to_s) || {}).reject{|v| v.blank? } )
      # end

      # after_destroy do
      #   TaskWorker.perform_async(id, 'destroy', tags.to_a)
      # end

      def create_feeds(ids)
        user_ids = (find_by_ids(ids).pluck("core_follows.follower_id")+self.user.followers.map{|q| q.present? ? q.id : nil }.reject{|i| i == nil}).uniq.freeze
        add_feeds_from_ids(user_ids)
        push_rongyun_system_mess user_ids, self
        return nil
      end

      def update_feeds(ids, ids_was)

        if ids.present?
          user_ids = find_by_ids(ids).pluck("core_follows.follower_id").uniq
          add_feeds_from_ids(user_ids)
        end
        if ids_was.present?
          now_users = find_by_ids((JSON.parse(self.star_list.to_s) || {}).reject{|v| v.blank? }).pluck("core_follows.follower_id").uniq
          user_ids = find_by_ids(ids_was).pluck("core_follows.follower_id").uniq
          remove_feeds_from_tags(user_ids-now_users)
        end
      end

      def remove_feeds(id, star_ids)
        users = (Follow.followers_scope_by_user_id(Core::Star.published.where(id: star_ids)).map(&:follower)+user.followers).uniq.compact
        return if users.blank?
        users.each do |u|
          u.feeds.remove(id)
        end
      end

      def top_feeds
        Core::User.active.pluck(:id).each do |user_id|
          next if task_state["#{shop_type}:#{user.id}"].to_i > 0 || self.expired_at.present? && Time.now > self.expired_at
          add_feed(user_id, shop.respond_to?(:end_at) && shop.end_at || 1.year.from_now, id)
        end
      end

      def user_feeds(user_id)
        Shop::Task.published.where(is_top: true).each do |t|
          next unless t.expired_at.blank? ||  Time.now > t.expired_at
          add_feed(user_id, t.expired_at || 1.year.from_now, t.id)
        end
      end

      def remove_feeds_from_tags(user_ids)
        user_ids.each do |user_id|
          $redis.del(feed_key_by_user_id(user_id))
        end
      end

      def add_feeds_from_ids(user_ids)
        return if user_ids.blank?
        user_ids.each do |user_id|
          next if self.task_state["#{self.shop_type}:#{user_id}"].to_i > 0
          add_feed(user_id, shop.respond_to?(:end_at) && shop.end_at || 1.year.from_now, id)
        end
      end

      # def find_by_ids(ids)
      #   Follow.followers_scope_by_user_id(Core::User.active.where(id: ids))
      # end

      def find_by_ids(ids)
        Follow.followers_scope_by_user_id(Core::Star.active.where(id: ids))
      end

      def add_feed(user_id, time=end_at, idendity=id)
        $redis.zadd(feed_key_by_user_id(user_id), time.utc.strftime("%s%L").to_i, idendity)
      end

      def feed_key_by_user_id(user_id)
        Core::User.redis_field_key :feeds, user_id
      end

      def push_rongyun_system_mess user_ids, task
        rc_rand = rand(100000)
        time = Time.now.to_i
        sign = rongyun_sign({'rc_rand' => rc_rand, 'time' => time})
        headers = {"RC-App-Key" => Rails.application.secrets.rongcloud.try(:[], "app_key"),
          "RC-Nonce" => rc_rand.to_s, "RC-Timestamp" => time.to_s, 'RC-Signature' => sign.to_s,
          "Content-Type" => "Application/x-www-form-urlencoded"}
        content =	{
          # "title": task.title,
          "content": task.title,
          # "imageUri": task.pic,
          # "URL": "#{Rails.application.routes.default_url_options[:host]}/#{task.shop_type.downcase.gsub("::", "/")}s/#{task.shop.id}",
          "taskID": task.shop.id.to_s,
          "extra": task.shop_type
        }.to_json
        circal_size = user_ids.size / 100
        (0..circal_size).each do |i|
          body = {
            fromUserId: 88,
            objectName: 'custom',
            content: content,
            pushContent: "#{task.star_names}有新的#{task.category == 'task' ? '任务' : '福利'}【#{task.title}】",
          }.sort.map{ |key, value| "#{key}=#{value}" }
          start_position = i * 100
          end_position = (i+1) * 100 - 1
          user_ids[start_position..end_position].each do |id|
            body << "toUserId=#{id}"
          end
          response = HTTParty.post("https://api.cn.ronghub.com/message/system/publish.json", {
            body: body.join('&'),
            headers: headers
          })
          if response['code'] == 200
            p ">>>>>>>>>>>>>>>>>>>>>>#{content}信息成功发送到#{user_ids[start_position..end_position]}"
          else
            p ">>>>>>>>>>>>>>>>>>>>>>#{content}信息失败发送到#{user_ids[start_position..end_position]}"
          end
          sleep 1
        end
        return nil

      end

      def rongyun_sign(option = {})
        app_secret = Rails.application.secrets.rongcloud.try(:[], "app_secret")
        rc_rand = option['rc_rand']
        time = option['time']
        sign = "#{app_secret}#{rc_rand}#{time}"
        return Digest::SHA1.hexdigest(sign)

      end
    end
  end
end
