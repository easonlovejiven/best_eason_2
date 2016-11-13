class ChangeFundingStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'change_funding_status', retry: true

  def perform(shop_order, platform, server=:change_funding_status)
    begin
      order = Shop::FundingOrder.find_by(order_no: shop_order['order_no'])
      pay_type = shop_order['pay_type'].to_i
      unless order.status == 'paid'
        ActiveRecord::Base.transaction do
          ticket_type = order.ticket_type
          order.update!(status: 2, pay_type: shop_order['pay_type'], paid_at: Time.now)
          ticket_type.participator.incr(order.try(:quantity) || 1)
          task = order.owhat_product.shop_task
          task.increment!(:participants)
          ShareWorker.perform_async(order.order_no, 'Shop::Funding')
          AwardWorker.perform_async(order.user.id, order.id, order.class.name, (order.payment.to_f.round(2)*0.1 < 1 ? 1 : (order.payment.to_f.round(2))*0.1), (order.payment.to_f.round(2)*0.1 < 1 ? 1 : (order.payment.to_f.round(2))*0.1), 'self', :award )
        end
      end
    rescue ActiveRecord::StatementInvalid
      p "#{Time.now}————————>error---------------->数据库表情符号错误"
    rescue Exception => e
      p e
    end

  end

end
