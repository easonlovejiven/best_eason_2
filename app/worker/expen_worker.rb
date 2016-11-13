class ExpenWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'expen', retry: true, backtrace: true

  def perform(task_id, user_id, options={})
    begin
      user = Core::User.find_by(id: user_id)
      user.create_welfare_lock.lock do
        @task = Shop::Task.find_by(id: task_id)
        raise "非福利任务！" unless @task.try(:category) == 'welfare'
        core_address = options["address_id"].present? ? Core::Address.find_by(id: options["address_id"]) : nil
        if @task.shop_type == "Welfare::Event" || @task.shop_type == "Welfare::Product"
          @ticket_type = Shop::TicketType.find_by(id: options["shop_ticket_type_id"])
          return raise "商品价格不存在" if @ticket_type.blank?
          return raise "该商品购买未开始" if @ticket_type.task.sale_start_at > Time.now
          return raise "该商品已购买结束" if @ticket_type.task.sale_end_at < Time.now
          return raise "该款商品: 每人限购" if @ticket_type.is_each_limit && options["quantity"].to_i > @ticket_type.each_limit
          return raise "该款商品: 购买超额啦" if @ticket_type.is_each_limit && (Core::Expen.where(user_id: user.id, shop_ticket_type_id: @ticket_type.id).sum(:quantity) + options["quantity"].to_i) > @ticket_type.each_limit
          return raise "该款商品当前购买人数已达上限" if @ticket_type.is_limit && @ticket_type.participator.value.to_i > @ticket_type.ticket_limit
        end

        obi = 5
        obi = options["fee"].to_i if @task.shop_type == 'Welfare::Event' || @task.shop_type == 'Welfare::Product'
        raise "O元不够" if obi > user.obi.to_i

        Core::Expen.transaction do
          expen = Core::Expen.create!(task_id: @task.id, resource_type: @task.shop_type, order_no: options["order_no"], address_id: options["address_id"], address: core_address.try(:full_address), phone: core_address.try(:mobile), user_name: core_address.try(:addressee), resource_id: @task.shop.id, amount: obi, currency: "Ocoin", user: user, action: "buy", status: options["status"], shop_ticket_type_id: @ticket_type.try(:id), quantity: options["quantity"])
          Shop::ExtInfoValue.create!(options["ext_infos"].map{|info| info.merge!({resource_id: expen.id, resource_type: 'Core::Expen'})}) if options["ext_infos"].present?
          p "#{Time.now}----------------> 免费福利报名成功 id: #{expen.id} 已创建"
        end
        user.update_attributes(obi: user.obi.to_i-obi)
        user.feeds.remove(@task.id)
        @task.increment!(:participants)
        @task.task_state["#{@task.shop_type}:#{user.id}"] += options["quantity"].present? ? options["quantity"].to_i : 1  if @task.shop_type == 'Welfare::Event' || @task.shop_type == 'Welfare::Product'

        @redis_order = Redis.current.get("welfare_order_by_#{options['order_no']}")
        if @redis_order.present?
          o = eval(@redis_order)
          Redis.current.set("welfare_order_by_#{options['order_no']}", o.merge!({:status => 2}))
        end
      end
    rescue StandardError => e
      if @task.shop_type == 'Welfare::Event' || @task.shop_type == 'Welfare::Product'
        @ticket_type.participator.decr(options["quantity"])
        now_size = Core::Expen.where(shop_ticket_type_id: @ticket_type.id, status: 'complete').map(&:quantity).sum
        @ticket_type.participator.value = now_size if @ticket_type.participator.value.to_i < now_size
        @redis_order = Redis.current.get("welfare_order_by_#{options['order_no']}")
        if @redis_order.present?
          o = eval(@redis_order)
          Redis.current.set("welfare_order_by_#{options['order_no']}", o.merge!({:error => e}))
        end
      end
      @task.task_state["#{@task.shop_type}:#{user.id}"] = 0  if @task.shop_type == 'Welfare::Letter' || @task.shop_type == 'Welfare::Voice'
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
  end
end
