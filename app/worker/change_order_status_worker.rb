class ChangeOrderStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'change_order_status', retry: true

  def perform(shop_order, platform, server=:change_order_status)
    order = Shop::Order.find_by(order_no: shop_order['order_no'])
    pay_type = shop_order['pay_type'].to_i
    unless order.status == 'paid'
      ActiveRecord::Base.transaction do
        order.order_items.each do |item|
          ticket_type = item.ticket_type
          #item.update!(status: 2, pay_type: pay_type, paid_at: shop_order['paid_at'])
          item.update!(status: 2, pay_type: pay_type, paid_at: Time.now)
          item.owhat_product.shop_task.increment!(:participants)
        end
        #order.update!(status: 2, pay_type: shop_order['pay_type'], paid_at: shop_order['paid_at'])
        order.update!(status: 2, pay_type: shop_order['pay_type'], paid_at: Time.now)
        AwardWorker.perform_async(order.user.id, order.id, order.class.name, (order.total_fee.to_f.round(2)*0.1 < 1 ? 1 : (order.total_fee.to_f.round(2)*0.1).to_i), (order.total_fee.to_f.round(2)*0.1 < 1 ? 1 : (order.total_fee.to_f.round(2)*0.1).to_i), 'self', :award )
      end
    end

  end

end
