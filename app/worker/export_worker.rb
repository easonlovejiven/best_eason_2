class ExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'export', retry: true, backtrace: true

  def perform(type, filename, options={})
    exported_order = Core::ExportedOrder.new(options.slice('user_id','user_type','task_id','task_type','paid_start_at','paid_end_at','order_class','exclude_free'))
    task_id = options['task_id']
    if options['user_type'] == "Core::User"
      user = Core::User.find_by(id: options['user_id'])
    else
      user = Manage::User.find_by(id: options['user_id'])
    end
    if options['withdraw_order_id'].present?
      # 提现申请订单
      this_withdraw_order = Core::WithdrawOrder.find_by(id: options['withdraw_order_id'])
      last_withdraw_order = Core::WithdrawOrder.where(task_id: task_id, task_type: options['task_type'], status: [1, 3]).where("id != ?", options['withdraw_order_id']).order(id: :desc).first
      this_requested_at = this_withdraw_order.requested_at
      if last_withdraw_order.present?
        last_requested_at = last_withdraw_order.requested_at
        case options['task_type']
        when 'Shop::Event'
          @orders = Shop::OrderItem.where(status:2, owhat_product_id: task_id, owhat_product_type: 'Shop::Event', active: true).where("paid_at >= ? AND paid_at < ?", last_requested_at.to_time.beginning_of_day.to_s(:db), this_requested_at.to_time.beginning_of_day.to_s(:db))
          if @orders.map(&:payment).sum.to_f.round(2) != this_withdraw_order.amount.to_f.round(2)
            @miss_orders = Shop::OrderItem.where(status:2, owhat_product_id: task_id, owhat_product_type: 'Shop::Event', active: true).where("paid_at <= ? AND updated_paid_at > ?", last_requested_at.to_time.beginning_of_day.to_s(:db), last_requested_at.to_time.beginning_of_day.to_s(:db))
            SendEmailWorker.perform_async(6, "问题订单请查看#{this_withdraw_order.id}来自提现组", "withdraw_order")
          end

        when 'Shop::Product'
          @orders = Shop::OrderItem.where(status:2, owhat_product_id: task_id, owhat_product_type: 'Shop::Product', active: true).where("paid_at >= ? AND paid_at < ?", last_requested_at.to_time.beginning_of_day.to_s(:db), this_requested_at.to_time.beginning_of_day.to_s(:db))
          if @orders.map(&:payment).sum.to_f.round(2) != this_withdraw_order.amount.to_f.round(2)
            @miss_orders = Shop::OrderItem.where(status:2, owhat_product_id: task_id, owhat_product_type: 'Shop::Product', active: true).where("paid_at <= ? AND updated_paid_at > ?", last_requested_at.to_time.beginning_of_day.to_s(:db), last_requested_at.to_time.beginning_of_day.to_s(:db))
            SendEmailWorker.perform_async(6, "问题订单请查看#{this_withdraw_order.id}, 来自提现组", "withdraw_order")
          end

        when 'Shop::Funding'
          @orders = Shop::FundingOrder.where(status:2, shop_funding_id: task_id, active: true).where("paid_at >= ? AND paid_at < ? ", last_requested_at.to_time.beginning_of_day.to_s(:db), this_requested_at.to_time.beginning_of_day.to_s(:db))
          if @orders.map(&:payment).sum.to_f.round(2) != this_withdraw_order.amount.to_f.round(2)
            @miss_orders = Shop::FundingOrder.where(status:2, shop_funding_id: task_id, active: true).where("paid_at <= ? AND updated_paid_at > ?", last_requested_at.to_time.beginning_of_day.to_s(:db), last_requested_at.to_time.beginning_of_day.to_s(:db))
            SendEmailWorker.perform_async(6, "问题订单请查看#{this_withdraw_order.id}, 来自提现组", "withdraw_order")
          end

        end
      else
        case options['task_type']
        when 'Shop::Event'
          @orders = Shop::OrderItem.where(status:2, owhat_product_id: task_id, owhat_product_type: 'Shop::Event', active: true).where("paid_at < ?", this_requested_at.to_time.beginning_of_day.to_s(:db))
        when 'Shop::Product'
          @orders = Shop::OrderItem.where(status:2, owhat_product_id: task_id, owhat_product_type: 'Shop::Product', active: true).where("paid_at < ?", this_requested_at.to_time.beginning_of_day.to_s(:db))
        when 'Shop::Funding'
          @orders = Shop::FundingOrder.where(status:2, shop_funding_id: task_id, active: true).where("paid_at < ?", this_requested_at.to_time.beginning_of_day.to_s(:db))
        end
      end
    else
      @orders = exported_order.all_orders
    end

    if type == 'csv'
      #需加上用户姓名 收货地址
      if options['task_type'] == 'Shop::Event' || options['task_type'] == 'Shop::Product' || options['order_class'] == 'Shop::OrderItem' || options['order_class'] == 'Shop::FundingOrder'
        columns = %w(id order_no owhat_product_id owhat_product_type user_id user_name phone address memo created_at quantity payment paid_at freight_fee platform)
      else
        columns = %w(id order_no shop_funding_id user_id user_name memo created_at quantity payment paid_at platform)
      end
      file = OwhatStringIO.new(filename, @orders.to_csv(:only => columns))
      exported_order.file_name = file
      exported_order.save!

    elsif type == 'xlsx'
      ac = ActionController::Base.new()
      @miss_orders.present? && @miss_orders.size > 0 ? locals = {orders: @orders, miss_orders: @miss_orders} : locals = {orders: @orders, miss_orders: nil, task_id: options['task_id'], task_type: options['task_type']}
      if options['task_type'] == 'Shop::Funding' || options['order_class'] == 'Shop::FundingOrder'
        temp = ac.render_to_string(handlers: [:axlsx], formats: [:xlsx], template: "home/backend/funding_export", layout: nil, locals: locals)
      elsif options['task_type'] == 'Welfare::Event' || options['task_type'] == 'Welfare::Product'|| options['order_class'] == 'Core::Expen'
        temp = ac.render_to_string(handlers: [:axlsx], formats: [:xlsx], template: "home/backend/welfare_export", layout: nil, locals: locals)
      else
        temp = ac.render_to_string(handlers: [:axlsx], formats: [:xlsx], template: "home/backend/export", layout: nil, locals: locals)
      end
      file = OwhatStringIO.new(filename, temp)
      exported_order.file_name = file
      exported_order.save!
    end
    #申请提现订单绑定
    if options['withdraw_order_id'].present?
      this_withdraw_order.update(core_exported_order_id: exported_order.id)
    end
  end
end
