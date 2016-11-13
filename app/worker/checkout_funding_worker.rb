class CheckoutFundingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'checkout_funding', retry: true

  def perform(shop_orders, sum_fee, address_id, order_no, freight_fee, platform, server=:checkout_funding)
    # raise "商品活动地址为空" unless address_id.present?
    ticket_type = Shop::TicketType.find_by(id: shop_orders[0]['ticket_type_id'])
    return raise  "该商品购买未开始" if ticket_type.task.sale_start_at > Time.now
    return raise "该商品已购买结束" if ticket_type.task.sale_end_at < Time.now
    return raise "该商品未发布" unless ticket_type.task.shop_task.published
    return raise "该款商品: 每人限购" if ticket_type.is_each_limit && shop_orders[0]['quantity'].to_i > ticket_type.each_limit
    return raise "该款商品: 购买超额啦" if ticket_type.is_each_limit && (Shop::FundingOrder.where(user_id: shop_orders[0]['user_id'].to_i, status: 2, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum + shop_orders[0]['quantity'].to_i) > ticket_type.each_limit
    return raise "该款商品当前购买人数已达上限" if ticket_type.is_limit && ticket_type.participator.value.to_i > ticket_type.ticket_limit
    return raise "价格不一致" if (shop_orders[0]['quantity'].to_i * ticket_type.fee.to_f.round(2)).to_f.round(2) != sum_fee.to_f.round(2)
    ActiveRecord::Base.transaction do
      if address_id.to_i == 0
        default_sql = "INSERT INTO `shop_funding_orders` (`order_no`, `owner_id`, `shop_funding_id`, `user_id`, `user_name`, `status`
        , `quantity`, `payment`, `phone`, `address`, `address_id`, `split_memo`, `memo`, `shop_ticket_type_id`, `platform`, `created_at`, `updated_at`)
          VALUES #{shop_orders.map {|o|
          ticket_type = Shop::TicketType.find_by(id: o['ticket_type_id']) and
          user = ticket_type.task.user and
          "('#{order_no}', #{user.id}, #{ticket_type.task_id}, #{o['user_id'].to_i},
          #{Core::User.find_by(id: o['user_id'].to_i).name.inspect}, 1,
          #{o['quantity']}, #{o['quantity'].to_i*ticket_type.fee.to_f.round(2)},
          '', '',
          #{address_id.to_i}, #{o['split_memo'].inspect}, #{o['info'].inspect}, #{o['ticket_type_id'].to_i},
          '#{platform}', '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" }.join(",") };"
      else
        default_sql = "INSERT INTO `shop_funding_orders` (`order_no`, `owner_id`, `shop_funding_id`, `user_id`, `user_name`, `status`
        , `quantity`, `payment`, `phone`, `address`, `address_id`, `split_memo`, `memo`, `shop_ticket_type_id`, `platform`, `created_at`, `updated_at`)
          VALUES #{shop_orders.map {|o|
          address = Core::Address.find_by(id: address_id.to_i) and
          ticket_type = Shop::TicketType.find_by(id: o['ticket_type_id']) and
          user = ticket_type.task.user and
          "('#{order_no}', #{user.id}, #{ticket_type.task_id}, #{o['user_id'].to_i},
          '#{address.try(:addressee)}', 1,
          #{o['quantity']}, #{o['quantity'].to_i*ticket_type.fee.to_f.round(2)},
          '#{address.try(:mobile)}', #{address ? address.full_address.inspect : ''},
          #{address_id.to_i}, #{o['split_memo'].inspect}, #{o['info'].inspect}, #{o['ticket_type_id'].to_i},
          '#{platform}', '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" }.join(",") };"
      end
      Shop::FundingOrder.connection.execute(default_sql)
      #免费任务
      if sum_fee.to_f.round(2) == 0
        ActiveRecord::Base.transaction do
          order = Shop::FundingOrder.find_by(order_no: order_no)
          user = order.user
          user.create_order_item_lock.lock do
            ticket_type = order.ticket_type
            return raise "该款商品: 购买超额啦" if ticket_type.is_each_limit && (Shop::FundingOrder.where(user_id: shop_orders[0]['quantity']['user_id'].to_i, status: 2, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum + shop_orders[0]['quantity'].to_i) > ticket_type.each_limit
            return raise "该款商品当前购买人数已达上限" if ticket_type.is_limit && ticket_type.participator.value.to_i > ticket_type.ticket_limit
            order.update(status: 2, paid_at: Time.now.to_s(:db), pay_type: 3)
            task = order.owhat_product.shop_task
            task.increment!(:participants)
            ticket_type.participator.incr(order.try(:quantity) || 1)
            task.get_obi(user)
            ShareWorker.perform_async(order.order_no, 'Shop::Funding')
          end
        end
      end
    end
  end

end
