class Shop::OrdersController < Shop::ApplicationController
  skip_before_filter :login_filter, only: [:alipay_direct_notify, :wx_pay_direct_notify, :wx_order_status]

  #用户订单界面
  def index
    if params[:from_release] == "old"
      page = (params[:page] || 1) - 1
      per = params[:per_page] || 100
      if @current_user.old_uid.blank? && @current_account.phone.present?
        user_id = $connection.connection.select_all("SELECT t.user_id FROM owhat.`tickets` as t WHERE t.sb_phone = #{@current_account.phone}").first['user_id'] rescue nil
        @current_user.update(old_uid: user_id) if user_id.present?
      end
      return @orders = [] if @current_user.old_uid.blank?
      @orders = $connection.connection.select_all("SELECT t.id, t.order_no, t.event_id, t.payment, e.start_at, t.name, t.pay_type, t.quantity, t.memo, e.title, e.cover1, e.product_type, t.address_id, t.paid_at, t.created_at, t.updated_at FROM owhat.`tickets` AS t, owhat.`events` AS e WHERE t.status = 2 AND t.user_id = #{@current_user.old_uid} AND t.event_id = e.id ORDER BY created_at DESC LIMIT #{per} OFFSET #{per*page}")
      @orders = [] unless @orders.present?
    else
      @orders = Shop::Order.active.where(user_id: @current_user.id, status: 1).order(created_at: :desc).includes([order_items: [:owhat_product, :ticket_type]]) if params[:status] == 'pending'
      @orders = Shop::Order.active.where(user_id: @current_user.id, status: 2).order(created_at: :desc).includes([order_items: [:owhat_product, :ticket_type]]) if params[:status] == 'paid'
      unless params[:status].present?
        @un_orders = Shop::Order.active.where(user_id: @current_user.id, status: 1).order(created_at: :desc).includes([order_items: [:owhat_product, :ticket_type]])
        @en_orders = Shop::Order.active.where(user_id: @current_user.id, status: 2).order(created_at: :desc).includes([order_items: [:owhat_product, :ticket_type]])
        @orders = @un_orders + @en_orders
      end
      @orders = @orders.paginate(page: params[:page] || 1, per_page: params[:per] || 10)
    end
  end

  def show
    @order = Shop::Order.find_by(order_no: params[:order_no])
    return (flash[:notice] =  '商品订单没找到' and redirect_to personal_center_home_users_path) unless @order.present?
    return (flash[:notice] =  '不能打开别人的订单哦' and redirect_to personal_center_home_users_path) if @order.user.id != @current_user.try(:id)
  end

  def create
    web_status = Shop::Order.web_order_create params[:shop_order], params[:address_id].to_i, params[:freight_fee], params[:sum_fee], @current_user
    return redirect_to :shop_orders, alert: web_status[1] if !web_status[0]
    #"shop_order"=>[{"info"=>"qq: 287715007  微博id: sun528  ", "quantity"=>"2", "ticket_type_id"=>"16", "user_id"=>"1"}, {"info"=>"qq: 287715007  微博id: sun528  ", "quantity"=>"2", "ticket_type_id"=>"20", "user_id"=>"1"}, {"info"=>"qq: qqqqqq  ", "quantity"=>"2", "ticket_type_id"=>"23", "user_id"=>"1"}, {"info"=>"微博id: sun528  ", "quantity"=>"2", "ticket_type_id"=>"24", "user_id"=>"1"}]
    order_no = UUID.generate(:compact)
    Redis.current.set("order_by_#{order_no}", {order_no: "#{order_no}", address_id: params[:address_id], status: 1, sum_fee: params[:sum_fee].to_f.round(2), shop_order: params[:shop_order], created_at: Time.now.to_s(:db) }.to_json )
    CheckoutCartsWorker.perform_async(params[:shop_order], params[:sum_fee].to_f, params[:address_id], order_no, params[:freight_fee], 'web', :checkout_carts)
    CoreLogger.info(controller: "Shop::Orders", action: 'create', order_no: order_no, current_user: @current_user.try(:id))
    if params[:sum_fee].to_f.round(2) != 0
      redirect_to payment_shop_order_path(id: order_no, shop_category: params[:shop_category] )
    else
      redirect_to :shop_orders, alert: "您的免费订单已进入支付队列，稍后请刷新，查看是否成功创建！"
    end
  end

  #支付方式选择界面
  def payment
    owhat_order = Shop::Order.where(active: true, order_no: params[:id]).first
    if owhat_order.present?
      return redirect_to shop_orders_path, alert: "您已经支付过了或已经取消，不要乱花钱哦" unless owhat_order.can_order_pay_and_cancel?
    end
    return redirect_to '/' unless Redis.current.get("order_by_#{params[:id]}").present?
    @order = eval( Redis.current.get("order_by_#{params[:id]}") )
    redirect_to '/' if @order[:shop_order][0][:user_id].to_i != @current_user.id
  end

  #支付成功页面
  def success
    @order = eval(Redis.current.get("order_by_#{params[:out_trade_no]}"))
    @order = Shop::Order.find_by(order_no: params[:out_trade_no])
    (return redirect_to :shop_orders, alert: "订单还在队列中排队哦，请稍后刷新看看!") unless @order
    user_id = @order.user_id
    rails "没有权限" if @current_user.id != user_id
    unless @order.status == 'paid'
      notify_params = params.except(*request.path_parameters.keys)
      if Alipay::Notify.verify?(notify_params)
        case params[:trade_status]
        when 'TRADE_SUCCESS', 'TRADE_FINISHED'
          @order = eval(Redis.current.get("order_by_#{params[:out_trade_no]}"))
          Redis.current.set("order_by_#{params[:out_trade_no]}", @order.update(status: 2).merge!({paid_at: params[:notify_time]}) )
          ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{params[:out_trade_no]}")), 'web', :change_order_status)
        end
        @order = eval(Redis.current.get("order_by_#{params[:out_trade_no]}"))
      else
        @order = eval(Redis.current.get("order_by_#{params[:out_trade_no]}"))
      end
    end
  end

  #取消订单
  def cancel
    @order = Shop::Order.find_by(id: params[:id])
    if @order.can_order_pay_and_cancel?
      ActiveRecord::Base.transaction do
        @order.cancel_alipay_weixin_order
        @order.update!(status: -2)
        @order.order_items.each do |o|
          o.update!(status: -2)
        end
        @order.order_items.each do |item|
          item.ticket_type.participator.decr(item.quantity)
        end
        CoreLogger.info(controller: "Shop::Orders", action: 'create', order_id: @order.try(:id), current_user: @current_user.try(:id))
      end
      redirect_to shop_orders_path, notice: "取消成功"
    else
      redirect_to shop_orders_path, alert: "取消失败"
    end
  end

  def alipay_direct_notify
    notify_params = params.except(*request.path_parameters.keys)
    if Alipay::Notify.verify?(notify_params)
      case params[:trade_status]
      when 'TRADE_SUCCESS', 'TRADE_FINISHED'
        @order = eval(Redis.current.get("order_by_#{params[:out_trade_no]}"))
        Redis.current.set("order_by_#{params[:out_trade_no]}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 1}) )
        ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{params[:out_trade_no]}")), 'web', :change_order_status)
      end
      render :text => 'success'
    else
      render :text => 'error'
    end
  end

  def wx_order_status
    @order = Shop::Order.find_by(order_no: params[:id])
    render json: { status: @order.status }, status: 200
  end

  def wx_pay_direct_notify
    result = Hash.from_xml(request.body.read)["xml"]

    if WxPay::Sign.verify?(result)
      if result['result_code'] == 'SUCCESS'
        @order = eval(Redis.current.get("order_by_#{result['out_trade_no']}"))
        Redis.current.set("order_by_#{result['out_trade_no']}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 2}) )
        ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{result['out_trade_no']}")), 'web', :change_order_status)
      end
      render :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
    else
      render :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
    end
  end

  #处理支付方式 跳转对应界面
  def settlement
    @order = Shop::Order.find_by(order_no: params[:id])
    return redirect_to :back, alert: "订单还在队列中排队，稍后在进行支付哦，如果长时间未成功，请尝试重新下单，可能您的队列中包含异常错误" unless @order
    return redirect_to :back, alert: "您没有默认地址请重新选择" unless @order.address_id.present?
    return redirect_to shop_orders_path, alert: "您已经支付过了，不要乱花钱哦" if @order.status == 'paid'
    return redirect_to shop_orders_path, alert: "订单已经取消" if @order.status == 'canceled'
    return redirect_to :back, alert: "订单已过期，请重新下单" if @order.status == 'deleted'
    return redirect_to :back, alert: "订单已过期，请重新下单" if Time.now > @order.expired_at
    return redirect_to shop_orders_path, alert: "您已经支付过了，不要乱花钱哦" unless @order.can_order_pay_and_cancel?
    @order.order_items.each do |order|
      ticket_type = Shop::TicketType.find_by(id: order.shop_ticket_type_id)
      array_status = ticket_type.created_order_options(order, order.quantity, @current_user, can_equal=false)
      return redirect_to :back, alert: array_status[1] if !array_status[0] #判断是否能够购买
    end
    get_freight_fee = Shop::OrderItem.calculate_freight_fee(@order.address_id,  @order.get_freight_fee_hash)
    return fail(0, "该地址不支持购买") if get_freight_fee[0] == '该地址不支持购买'
    return redirect_to :back, alert: "邮费价格结算错误，请重新结算(可能您的地址编辑出现问题， 请将地址必填项填好。)" if get_freight_fee[0] == false || @order.freight_fee != get_freight_fee[1].values.sum
    @order.update(platform: 'web') unless @order.platform == 'web'
    bank = params[:banks]
    @redis_order = eval(Redis.current.get("order_by_#{params[:id]}")).merge!({:expired_at => @order.expired_at.to_s(:db)})
    Redis.current.set("order_by_#{params[:id]}", @redis_order )
    if bank == 'alipay'
      alipay_direct_url = Shop::OrderHelper.alipay_direct_url(@redis_order.merge(web_type: params[:web_type] || 'web'))
      if  alipay_direct_url.present?
        redirect_to alipay_direct_url and return
      else
        redirect_to :back, alert: "您的支付在支付方可能超时啦, 请重新下单吧" and return
      end
    elsif bank == 'wx_pay'
      wx_pay_direct_url = Shop::OrderHelper.wx_pay_direct_url(@redis_order, request.remote_ip == "::1" ? '127.0.0.1' : request.remote_ip)
      if wx_pay_direct_url.present?
        redirect_to wx_pay_direct_url and return
      else
        redirect_to :back, alert: "微信服务器出了一些问题，重试一下吧！" and return
      end
    else
      alipay_direct_url = Shop::OrderHelper.alipay_direct_url(@redis_order)
      if  alipay_direct_url.present?
        redirect_to alipay_direct_url and return
      else
        redirect_to :back, alert: "您的支付在支付方可能超时啦, 请重新下单吧" and return
      end
    end
  end

  #微信二维码支付页面
  def wx_qr_code
    order = Shop::Order.find_by(order_no: params[:id])
    return redirect_to shop_orders_path, alert: "您已经支付过了，不要乱花钱哦" unless order.can_order_pay_and_cancel?
  end

  private

  def shop_order_params
    params.require(:shop_order)
      .permit(:id, :guide, :title, :shop_category, :description,
       star_list: [])
  end

end
