namespace :import do
  desc "导入第三方关联账户"
  task connection_user: :environment do
    owhat2_id = Core::Connection.where("owhat2_id IS NOT NULL").last.try(:owhat2_id) || 1
    10000.times do |i|
      pre = 1000
      identities = $connection.connection.select_all("SELECT id, user_id, provider, token, uid, avatar_large, created_at, updated_at FROM owhat.`identities` WHERE id > #{owhat2_id} ORDER BY id ASC LIMIT #{pre} OFFSET #{i*pre}")
      break if identities.blank?
      identities.each do |identity|
        puts identity['id']
        next if identity['user_id'].blank? || identity['uid'].blank? || identity['provider'].blank?
        user = Core::User.find_by(old_uid: identity['user_id'])
        next unless user
        site = identity['provider'] == 'qq_connect' ? 'qq' : identity['provider']
        connection = Core::Connection.active.find_or_initialize_by(identifier: identity['uid'], site: site)
        next if connection.id
        connection.name = user.name
        connection.sex = user.sex
        connection.account_id = user.id
        connection.token = identity['token']
        connection.pic = identity['avatar_large']
        connection.created_at = identity['created_at']
        connection.updated_at = identity['updated_at']
        connection.owhat2_id = identity['id']
        connection.expired_at = 7.days.from_now
        connection.save
      end
    end
  end

  desc "导入关注粉丝"
  task :followers, [:id] => :environment do |t, args|
    10000.times do |i|
      pre = 1000
      id = args[:id].to_i
      users = Core::User.active.where("id > #{id} AND old_uid IS NOT NULL").select("id, name, old_uid").page(i+1).per_page(pre)
      break if users.blank?
      users.each do |user|
        puts "id: #{user.id}, old_uid: #{user.old_uid}"
        next if [46, 120].include? user.old_uid
        #粉丝数
        followers = $connection.connection.select_all("SELECT owhat.`follows`.follower_id FROM owhat.`follows` WHERE owhat.`follows`.`followable_id` = #{user.old_uid} AND owhat.`follows`.`followable_type` = 'User'")
        followers.each do |f|
          follower = Core::User.find_by old_uid: f['follower_id']
          next if follower.nil? || follower.following?(user)
          follower.follow_and_update_cache(user)
        end
        #关注数
        # follows = $connection.connection.select_all("SELECT `follows`.followable_id FROM `follows` WHERE `follows`.`follower_id` = #{user.old_uid} AND `follows`.`follower_type` = 'User' AND `follows`.`blocked` = 0 AND `follows`.`followable_type` = 'User'")
        # follows.each do |f|
        #   following = Core::User.find_by old_uid: f['follow_id']
        #   next unless following
        #   user.follow_and_update_cache(following) unless user.following? following
        # end
      end
    end
  end

  # task fans: :environment do
  #   users = Core::User.active.where("verified is true and old_uid IS NOT NULL")
  #   users.each do |user|
  #     puts "id: #{user.id}, old_uid: #{user.old_uid}"
  #     #粉丝数
  #
  #     old_user = $connection.connection.select_all("SELECT owhat.`users`.* FROM owhat.`users` WHERE owhat.`users`.`id` = #{user.old_uid}").first rescue nil
  #
  #     user.update_attributes(name: ,pic: u.avatar.url)
  #     followers = $connection.connection.select_all("SELECT owhat.`follows`.follower_id FROM owhat.`follows` WHERE owhat.`follows`.`followable_id` = #{user.old_uid} AND owhat.`follows`.`followable_type` = 'User'")
  #     followers.each do |f|
  #       follower = Core::User.find_by old_uid: f['follower_id']
  #       next if follower.nil? || follower.following?(user)
  #       follower.follow_and_update_cache(user)
  #     end
  #   end
  # end


  desc "导入最新用户old_uid to owhat3"
  task import_old_uids: :environment do
    Core::User.where("id > ?", 611044).each do |user|
      p "----------------> #{user.id}"
      old_user = $connection.connection.select_all("SELECT id, nickname FROM owhat.`users` WHERE nickname = '#{user.name}'").first
      if old_user.present?
        p "old_uid 和新的重合 正在导出。。。。。。#{old_user["nickname"]}   #{old_user["id"]}"
        p "更新成功。。。" if user.update(old_uid: old_user['id'])
      end
    end
  end

  desc "同步第三方账户"
  task sync_connection: :environment do
    Core::Connection.active.where("owhat2_id IS NULL").each do |connection|
      identity =  $connection.connection.select_all("SELECT owhat.`identities`.* FROM owhat.`identities` WHERE owhat.`identities`.`uid` = '#{connection.identifier}'").first rescue nil
      next if identity.blank?
      user = connection.account.user
      p user.id
      user.update_attributes(old_uid: identity['user_id']) if user.old_uid.nil? && identity['user_id'].present?
    end
  end

  desc "订单同步总订单号"
  task sync_basic_order_no: :environment do
    Shop::OrderItem.find_each do |o|
      next if o.order.blank?
      basic_order_no = o.order.order_no
      p ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>basic_order_no: #{basic_order_no}"
      p "================================> 更新成功 #{o.id}"if o.update(basic_order_no: basic_order_no)
    end
  end

end
