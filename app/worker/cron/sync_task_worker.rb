class SyncTaskWorker
  #清除过期订单
  include Sidekiq::Worker
  sidekiq_options queue: 'sync'

  def perform
    #定时任务每天自动更新一下价格
    Shop::Task.where(shop_type: ['Shop::Event', 'Shop::Product', 'Shop::Funding', 'Welfare::Event', 'Welfare::Product']).where('expired_at > ?', Time.now).includes(:shop).find_each do |task|
      task.shop.ticket_types.each do |type|
        ticket_type = Shop::TicketType.find_by(id: type)
        if task.shop_type == 'Shop::Funding'
          p "#{Time.now}————————> owhat_product价格id: #{type.id} 已更新参与人数"
          ticket_type.participator.value = Shop::FundingOrder.where(shop_ticket_type_id: type, status: 2).size
        elsif task.shop_type == 'Welfare::Product' || task.shop_type == 'Welfare::Event'
          ticket_type.participator.value = Core::Expen.where(shop_ticket_type_id: ticket_type.id).map(& :quantity).sum
        else
          p "#{Time.now}————————> owhat_product价格id: #{type.id} 已更新参与人数"
          order = Shop::OrderItem.where(shop_ticket_type_id: type, status: 2)
          ticket_type.participator.value = Shop::OrderItem.where(shop_ticket_type_id: type, status: 1).map(& :quantity).sum + order.map(& :quantity).sum
        end
      end
      if task.shop_type == 'Shop::Funding'
        size = Shop::FundingOrder.where(shop_funding_id: task.shop_id, status: 2).size
        task.update(participants: size)
      elsif task.shop_type == 'Welfare::Event' || task.shop_type == 'Welfare::Product'
        size = Core::Expen.where(task_id: task.id).map(& :quantity).sum
        task.update(participants: size)
      else
        size = Shop::OrderItem.where(owhat_product_id: task.shop_id, owhat_product_type: task.shop_type, status: 2).size
        task.update(participants: size)
      end
    end

    task_count = Shop::Task.active.where("updated_at > ?", 1.days.ago).count
    Core::Finding.active.find_by(category: 'task').update_attributes(count: task_count)
    # star_count = Core::Star.published.where("created_at > ?", 1.days.ago).count
    star_count = Core::Star.published.count
    Core::Finding.active.find_by(category: 'star').update_attributes(count: star_count)
    # org_count = Core::User.active.where("identity = 2 AND created_at > ?", 1.days.ago).count
    org_count = Core::User.active.where("identity = 2").count
    Core::Finding.active.find_by(category: 'org').update_attributes(count: org_count)
    fans_count = Core::User.active.where("identity = 1").count
    Core::Finding.active.find_by(category: 'fans').update_attributes(count: fans_count)
  end
end
