class SendDayMailWork
  #每晚邮件报告
  include Sidekiq::Worker
  sidekiq_options queue: 'send_day'

  def perform
    begin_time = Time.now.beginning_of_day - 1.day
    end_time = begin_time.end_of_day
    #之前用户数
    l_users = Core::User.where("created_at < ?", begin_time).size
    #当前用户数
    n_users = Core::User.where("created_at BETWEEN ? AND ?", begin_time, end_time).size
    #已支付订单数
    p_event_orders = Shop::OrderItem.where("created_at BETWEEN ? AND ? AND status = ?", begin_time, end_time, 2).size
    #总订单数
    event_orders = Shop::OrderItem.where("created_at BETWEEN ? AND ?", begin_time, end_time).size
    event_payments = (Shop::OrderItem.select("SUM(payment) AS payment").where("created_at BETWEEN ? AND ? AND status = ?", begin_time, end_time, 2).first.try(:payment) || 0).to_f.round(2)
    p_funding_orders = Shop::FundingOrder.where("created_at BETWEEN ? AND ? AND status = ?", begin_time, end_time, 2).size
    funding_orders = Shop::FundingOrder.where("created_at BETWEEN ? AND ?", begin_time, end_time).size
    funding_payments = (Shop::FundingOrder.select("SUM(payment) AS payment").where("created_at BETWEEN ? AND ? AND status = ?", begin_time, end_time, 2).first.try(:payment) || 0).to_f.round(2)
    all_users = Core::User.all.size #总用户
    pay_orders = p_event_orders + p_funding_orders #总支付订单
    all_orders = event_orders + funding_orders #全部订单
    all_payments = (event_payments + funding_payments).to_f.round(2) #全部支付金额
    Core::Mailer.mail(
      recipients: 'report@owhat.cn',
      subject: "owhat3系统统计报告 #{begin_time.strftime("%Y-%m-%d")}",
      template: 'day',
      body: { all_users: all_users, pay_orders: pay_orders, all_orders: all_orders, all_payments: all_payments, n_users: n_users  },
      from: %["Owhat!" <#{MAILER_CONFIG['from']['activation']}>]
    )
    h = eval(Redis.current.get("shop_order_sum_pay_for_day"))
    f = eval(Redis.current.get("shop_funding_order_sum_pay_for_day"))
    Redis.current.set("shop_order_sum_pay_for_day", {sum: (event_payments+h[:sum].to_f.round(2)).to_f.round(2)}.to_json )
    Redis.current.set("shop_funding_order_sum_pay_for_day", {sum: (funding_payments+f[:sum].to_f.round(2)).to_f.round(2)}.to_json )
  end
end
