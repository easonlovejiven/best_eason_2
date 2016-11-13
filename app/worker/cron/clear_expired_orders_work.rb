class ClearExpiredOrdersWorker
  #清除过期订单
  include Sidekiq::Worker
  include OrderHelper
  sidekiq_options queue: 'clear'

  def perform
    ticket_type_ids = []
    Shop::Order.time_out.includes([order_items: :owhat_product]).find_each do |order|
      ticket_type_ids += shop_order_scan order
    end
    ticket_type_ids = ticket_type_ids.uniq
    ticket_type_ids.each do |type|
      ticket_type = Shop::TicketType.find_by(id: type)
      ticket_type.participator.value = Shop::OrderItem.where(shop_ticket_type_id: type, status: 1).map(& :quantity).sum + Shop::OrderItem.where(shop_ticket_type_id: type, status: 2).map(& :quantity).sum
      p "#{Time.now}————————> owhat_product价格id: #{type} 已更新参与人数 #{ticket_type.participator.value}"
    end


    #每五分钟清空一次应援
    ticket_type_ids = []
    Shop::FundingOrder.where(status: 1).where("created_at < ?", Time.now-20.minutes).find_each do |order|
      ticket_type_ids += shop_order_scan order
    end
    ticket_type_ids = ticket_type_ids.uniq

    ticket_type_ids.each do |f|
      ticket_type = Shop::TicketType.find_by(id: f)
      ticket_type.participator.value = Shop::FundingOrder.where(shop_ticket_type_id: f, status: 2).size
    end

    ticket_type_id = nil

    time = Time.now - 5.minutes
    Shop::Task.where("updated_at > ?", time).each do |t|
      active = t.shop.active
      t.update(active: active)
    end
    Core::Star.where("updated_at > ?", time).each do |t|
      active = t.active
      published = t.published
      t.update(active: active, published: published)
    end
    Core::User.where("updated_at > ?", time).each do |t|
      active = t.active
      t.update(active: active)
    end

    return nil

  end
end
