class CheckoutCartsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'checkout_carts', retry: true

  def perform(shop_orders, sum_fee, address_id, order_no, freight_fee, platform, server=:checkout_carts)
    begin
      total_fee = 0
      shop_orders.each do |o|
        ticket_type = Shop::TicketType.find_by(id: o['ticket_type_id'])
        total_fee += ticket_type.fee.to_f.round(2)*o['quantity'].to_i
        return raise "该商品购买未开始" if ticket_type.task.sale_start_at > Time.now
        return raise "该商品已购买结束" if ticket_type.task.sale_end_at < Time.now
        return raise "该商品未发布" unless ticket_type.task.shop_task.published
        return raise "该款商品: 每人限购" if ticket_type.is_each_limit && o['quantity'].to_i > ticket_type.each_limit
        return raise "该款商品当前购买人数已达上限" if ticket_type.is_limit && ticket_type.participator.value.to_i > ticket_type.ticket_limit
        return raise "该款商品: 购买超额啦" if ticket_type.is_each_limit && ((Shop::OrderItem.where(user_id: o['user_id'].to_i, status: 2, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum+Shop::OrderItem.where(user_id: o['user_id'].to_i, status: 1, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum)+ o['quantity'].to_i) > ticket_type.each_limit
        return raise "该款商品当前购买人数已达上限" if ticket_type.is_limit && (Shop::OrderItem.where(shop_ticket_type_id: ticket_type.id, status: 1).map(&:quantity).sum+Shop::OrderItem.where(shop_ticket_type_id: ticket_type.id, status: 2).map(&:quantity).sum) > ticket_type.ticket_limit
      end
      return raise "#{Time.now}————————>error---------------->shop_orders: #{shop_orders}, 恶意刷单total_fee:#{total_fee.to_f.round(2) + freight_fee.to_f.round(2)}, sum_fee: #{sum_fee}"  if (total_fee.to_f.round(2) + freight_fee.to_f.round(2)).to_f.round(2) != sum_fee.to_f.round(2)

      return raise "#{Time.now}————————>error---------------->商品活动地址为空" unless address_id.present?
      ActiveRecord::Base.transaction do
        #默认过期时间20分钟 因为不同的商品可能过期时间并不相同
        order = Shop::Order.create!(order_no: order_no, total_fee: sum_fee, status: 1, address_id: address_id, user_id: shop_orders[0]['user_id'].to_i, freight_fee: freight_fee.to_f.round(2), platform: platform, expired_at: (Time.now + 20*60).to_s(:db))
        default_sql = "INSERT INTO `shop_order_items` (`basic_order_no`, `order_no`, `owner_id`, `owhat_product_id`, `owhat_product_type`, `user_id`, `user_name`, `phone`, `address`, `status`
        , `quantity`, `payment`, `address_id`, `freight_fee`, `split_memo`, `memo`, `shop_ticket_type_id`, `order_id`, `platform`, `expired_at`, `created_at`, `updated_at`)
          VALUES #{shop_orders.map {|o|
          address = Core::Address.find_by(id: address_id) and
          ticket_type = Shop::TicketType.find_by(id: o['ticket_type_id']) and
          user = ticket_type.task.user and
          "('#{order_no}', '#{UUID.generate(:compact)}', #{user.id}, #{ticket_type.task_id},
          '#{ticket_type.task_type}', #{o['user_id'].to_i}, '#{address.try(:addressee)}',
          '#{address.try(:mobile)}', #{address ? address.full_address.inspect : ''}, 1
          , #{o['quantity']}, #{o['quantity'].to_i*ticket_type.fee.to_f.round(2)+o['freight_fee'].to_f},
           #{address_id.to_i}, #{o['freight_fee'].to_f}, #{o['split_memo'].inspect}, #{o['info'].inspect},
           #{o['ticket_type_id'].to_i}, #{order.id}, '#{platform}', '#{(Time.now + ticket_type.task.trade_expired_time*60).to_s(:db) }', '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" }.join(",") };"
        Shop::OrderItem.connection.execute(default_sql)
        if sum_fee.to_f.round(2) == 0 && freight_fee.to_f.round(2) == 0
          user = order.user
          user.create_order_item_lock.lock do
            order.order_items.includes(:ticket_type).each do |item|
              ticket_type = item.ticket_type
              return raise "该款商品: 购买超额啦" if ticket_type.is_each_limit && (Shop::OrderItem.where(user_id: user.id, status: 2, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum + item.quantity) > ticket_type.each_limit
              return raise "该款商品当前购买人数已达上限" if ticket_type.is_limit && ticket_type.participator.value.to_i > ticket_type.ticket_limit
              item.update!(status: 2, pay_type: 3, paid_at: Time.now.to_s(:db))
              item.owhat_product.shop_task.increment!(:participants)
              item.owhat_product.shop_task.get_obi(user)
            end
            order.update!(status: 2, paid_at: Time.now.to_s(:db), pay_type: 3)
          end
        end
        @redis_order = Redis.current.get("order_by_#{order_no}")
        if @redis_order.present?
          o = eval(@redis_order)
          o = o.update(status: 2) if sum_fee.to_f.round(2) == 0 && freight_fee.to_f.round(2) == 0
          Redis.current.set("order_by_#{order_no}", o.merge!({:created_status => 1}))
        end
      end
    rescue ActiveRecord::StatementInvalid
      p "#{Time.now}————————>数据库表情符号错误"
      decr_participator shop_orders, order_no, "数据库表情符号错误"
    rescue Exception => e
      p e
      decr_participator shop_orders, order_no, "异常：#{e}"
    end

  end

  def decr_participator shop_orders, order_no, error
    @redis_order = Redis.current.get("order_by_#{order_no}")
    if @redis_order.present?
      o = eval(@redis_order)
      Redis.current.set("order_by_#{order_no}", o.merge!({:error => error}))
    end
    ActiveSupport::Notifications.instrument "owhat.order_items", {order: "#{shop_orders}", error: "#{error}"}
    shop_orders.each do |o|
      ticket_type = Shop::TicketType.find_by(id: o['ticket_type_id'])
      now_size = Shop::OrderItem.where(shop_ticket_type_id: ticket_type.id, status: 1).map(&:quantity).sum+Shop::OrderItem.where(shop_ticket_type_id: ticket_type.id, status: 2).map(&:quantity).sum
      ticket_type.participator.decr(o['quantity'])
      ticket_type.participator.value = now_size if ticket_type.participator.value.to_i < now_size
    end
  end

end
