class AwardWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'award', retry: true, batch_flush_size: 10, batch_size: 1

  # def perform(user_id, task_id, task_type, empirical_value, obi, from, server=:award)
  def perform(*args)
    user_id, task_id, task_type, empirical_value, obi, from = args[0][0][0], args[0][0][1], args[0][0][2], args[0][0][3], args[0][0][4], args[0][0][5]
    empirical_value = empirical_value.to_i
    obi = obi.to_i
    user = Core::User.find_by(id: user_id)
    return p "#{Time.now}————————>error---------------->用户不对！"  unless user.present?
    size = Core::TaskAward.where(user_id: user_id, task_type: task_type).where("created_at > ? ", Time.now.beginning_of_day.to_s(:db)).size
    case task_type
    when 'Shop::DynamicComment'
      if size <= 50
        Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from )
        user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
      end
      comment = Shop::DynamicComment.find_by(id: task_id)
      comment.dynamic.topic.shop_task.get_obi user
      comment.dynamic.topic.shop_task.increment!(:participants)
    when 'Shop::VoteResult'
      if size <= 50
        Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from )
        user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
      end
      vote_result = Shop::VoteResult.find_by(id: task_id)
      vote_result.resource.topic.shop_task.get_obi user
      vote_result.resource.topic.shop_task.increment!(:participants)
    when 'Shop::TopicDynamic'
      topic = Shop::TopicDynamic.find_by(id: task_id).topic
      if from.match(/._share/)
        topic.shop_task.share_state["#{Shop::Topic}:#{user.id}"] += 1
        share_size = Core::TaskAward.where(user_id: user_id, task_type: task_type).where("`from` like '%_share' AND created_at > ? ", Time.now.beginning_of_day.to_s(:db)).size #分享次数

        if share_size < 20
          Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from)
          user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
        end
      end
      #创建动态
      create_size = Core::TaskAward.where(user_id: user_id, task_type: task_type, from: "create_topic_dynamic").where("created_at > ? ", Time.now.beginning_of_day.to_s(:db)).size
      #点赞
      like_size = Core::TaskAward.where(user_id: user_id, task_type: task_type, from: "self").where("created_at > ? ", Time.now.beginning_of_day.to_s(:db)).size
      #被别人点赞次数
      liked_size = Core::TaskAward.where(user_id: user_id, task_type: task_type, from: "other").where("created_at > ? ", Time.now.beginning_of_day.to_s(:db)).size

      if (from == 'self' && like_size <= 5) || (from == 'other' && liked_size <= 50) || from == 'create_topic_dynamic' && create_size <= 5
        Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from )
        user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
      end
      if from == 'self' || from == "create_topic_dynamic"
        topic.shop_task.get_obi user
        topic.shop_task.increment!(:participants)
      end
    when 'Shop::Comment'
      if size <= 50
        Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from )
        user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
      end
      comment = Shop::Comment.find_by(id: task_id)
      comment.task.shop_task.get_obi user
      comment.task.shop_task.increment!(:participants)
    when 'Shop::FundingOrder'
      if size <= 50
        Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from )
        user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
      end
      order = Shop::FundingOrder.find_by(id: task_id)
      task = order.owhat_product.shop_task
      #task.increment!(:participants)
      task.get_obi(user)
    when 'Shop::Order'
      if size <= 50
        Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from)
        user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
      end
      order = Shop::Order.find_by(id: task_id)
      order.order_items.each do |item|
        #item.owhat_product.shop_task.increment!(:participants)
        item.owhat_product.shop_task.get_obi(user)
      end
    when 'Core::User', 'Core::Star', 'Qa::Poster', "Shop::Event", "Shop::Product", "Shop::Topic", "Shop::Media", "Shop::Subject", "Shop::Funding"
      if from.match(/._share/)
        if task_type != 'Core::User' && task_type != 'Core::Star'
          task = eval(task_type).find_by(id: task_id).shop_task
          task.share_state["#{task.shop_type}:#{user.id}"] += 1
          task.get_obi(user, type: 'share')
        end
        share_size = Core::TaskAward.where(user_id: user_id, task_type: task_type).where("`from` like '%_share' AND created_at > ? ", Time.now.beginning_of_day.to_s(:db)).size
        if share_size < 20
          Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from)
          user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
        end
      else
        #发任务暂时不送O元 包含媒体任务参与 打卡任务
        if task_type != 'Core::User' && task_type != 'Core::Star'
          task = eval(task_type).find_by(id: task_id).shop_task
          task.get_obi user
          task.increment!(:participants)
        end
        Core::TaskAward.create(user_id: user_id, task_id: task_id, task_type: task_type, empirical_value: empirical_value, obi: obi, from: from)
        user.update(empirical_value: user.empirical_value+empirical_value, obi: user.obi+obi)
      end
    end

    level, obi = user.update_obi_and_empirical_value(user.empirical_value, user)
    unless user.level == level
      Core::TaskAward.create(user_id: user_id, task_id: user.id, task_type: user.class, empirical_value: 0, obi: (obi - user.obi), from: 'level_up')
      user.update(level: level, obi: obi)
    end
  end
end
