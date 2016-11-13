class WebSyncTaskWorker
  include Sidekiq::Worker
  include OrderHelper
  sidekiq_options queue: 'web_sync'

  def perform
    time = Time.now - 3.minutes
    ticket_type_ids = []
    Shop::Order.where(status: -1).where("updated_at > ?", Time.now-5.minutes ).each do |order|
      ticket_type_ids += shop_order_scan order
    end
    ticket_type_ids = ticket_type_ids.uniq
    ticket_type_ids.each do |type|
      ticket_type = Shop::TicketType.find_by(id: type)
      ticket_type.participator.value = Shop::OrderItem.where(shop_ticket_type_id: type, status: 1).map(& :quantity).sum+Shop::OrderItem.where(shop_ticket_type_id: type, status: 2).map(& :quantity).sum
    end
    ticket_type_ids = []
    Shop::FundingOrder.where(status: -1).where("updated_at > ?", Time.now-5.minutes ).find_each do |order|
      ticket_type_ids += shop_order_scan order
    end
    ticket_type_ids = ticket_type_ids.uniq

    ticket_type_ids.each do |f|
      ticket_type = Shop::TicketType.find_by(id: f)
      ticket_type.participator.value = Shop::FundingOrder.where(shop_ticket_type_id: f, status: 2).size
    end


    Shop::Event.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
    end
    Shop::Product.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
    end
    Shop::Funding.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
    end
    Shop::Topic.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
    end
    Shop::Media.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
    end
    Shop::Subject.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
    end
    Welfare::Event.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
    end
    Welfare::Product.where("updated_at > ?", time).each do |t|
      active = t.active
      t.shop_task.update(active: active)
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

  end
end
