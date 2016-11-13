class Shop::FundingOrdersController < Shop::ApplicationController
  skip_before_filter :login_filter, only: [:alipay_direct_notify, :wx_pay_direct_notify]

  #用户订单界面
  def index
    @orders = Shop::FundingOrder.active.where(user_id: @current_user.id, status: [1, 2])
    @orders = @orders.where(status: 1) if params[:status] == 'pending'
    @orders = @orders.where(status: 2) if params[:status] == 'paid'
    @orders = @orders.paginate(page: params[:page] || 1, per_page: params[:per] || 10).order(created_at: :desc)
  end

  def show
    @order = Shop::FundingOrder.find_by(order_no: params[:order_no])
    return (flash[:notice] =  '应援订单没找到' and redirect_to personal_center_home_users_path) unless @order.present?
    return (flash[:notice] =  '不能打开别人的订单哦' and redirect_to personal_center_home_users_path) if @order.user.id != @current_user.try(:id)
  end

  def create
    order = params[:shop_order][0]
    ticket_type = Shop::TicketType.find_by(id: order[:ticket_type_id])
    array_status = ticket_type.created_order_options(order, order[:quantity], @current_user)
    return redirect_to :back, alert: array_status[1] if !array_status[0] #判断是否能够购买
    return redirect_to :back, alert: "不要擅自修改价格哦！！！" if (ticket_type.fee.to_f.round(2) * order[:quantity].to_i).to_f.round(2) != params[:sum_fee].to_f.round(2)
    order_no = UUID.generate(:compact)
    Redis.current.set("funding_order_by_#{order_no}", {order_no: "#{order_no}", address_id: params[:address_id], status: 1, sum_fee: params[:sum_fee].to_f.round(2), shop_order: params[:shop_order], created_at: Time.now.to_s(:db) }.to_json )
    CheckoutFundingWorker.perform_async(params[:shop_order], params[:sum_fee].to_f, params[:address_id], order_no, params[:freight_fee], 'web', :checkout_funding)
    CoreLogger.info(controller: "Shop::FundingOrders", action: 'create', order_no: order_no, current_user: @current_user.try(:id))
    if params[:sum_fee].to_f.round(2) != 0
      redirect_to payment_shop_funding_order_path(id: order_no, shop_category: params[:shop_category] )
    else
      redirect_to success_shop_funding_order_path(out_trade_no: order_no, id: order_no, total_fee: params[:sum_fee])
    end
  end

  #支付方式选择界面
  def payment
    funding_order = Shop::FundingOrder.where(active: true, order_no: params[:id]).first
    if funding_order.present?
      return redirect_to shop_funding_orders_path, alert: "您已经支付过了或已经取消，不要乱花钱哦" unless funding_order.can_order_pay_and_cancel?
    end
    return redirect_to '/' unless Redis.current.get("funding_order_by_#{params[:id]}").present?
    @order = eval( Redis.current.get("funding_order_by_#{params[:id]}") )
    redirect_to '/' if @order[:shop_order][0][:user_id].to_i != @current_user.id
  end

  #支付成功页面
  def success
    funding_order = @order = Shop::FundingOrder.find_by(order_no: params[:out_trade_no])
    (return redirect_to shop_funding_orders_path, alert: "订单还在队列中排队，稍后在进行支付哦") unless @order
    user_id = @order.user_id
    unless @order.status == 'paid'
      notify_params = params.except(*request.path_parameters.keys)
      if Alipay::Notify.verify?(notify_params)
        case params[:trade_status]
        when 'TRADE_SUCCESS', 'TRADE_FINISHED'
          @order = eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}"))
          Redis.current.set("funding_order_by_#{params[:out_trade_no]}", @order.update(status: 2).merge!({paid_at: params[:notify_time]}) )
          ChangeFundingStatusWorker.perform_async(eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}")), 'web', :change_funding_status)
        end
        @order = eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}"))
      else
        @order = eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}"))
      end
    end
    @share_info = funding_order.share_info
    @funding = funding_order.owhat_product
    @weibo_auto_share = funding_order.user.weibo_auto_share_info
  end

  def cancel
    @order = Shop::FundingOrder.find_by(id: params[:id])
    if @order.can_order_pay_and_cancel?
      ActiveRecord::Base.transaction do
        @order.cancel_alipay_weixin_order
        @order.update!(status: -2)
        CoreLogger.info(controller: "Shop::FundingOrders", action: 'cancel', order_id: @order.try(:id), current_user: @current_user.try(:id))
      end
      redirect_to shop_funding_orders_path, notice: "取消成功"
    else
      redirect_to shop_funding_orders_path, alert: "取消失败"
    end
  end

  def alipay_direct_notify
    notify_params = params.except(*request.path_parameters.keys)
    if Alipay::Notify.verify?(notify_params)
      case params[:trade_status]
      when 'TRADE_SUCCESS', 'TRADE_FINISHED'
        @order = eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}"))
        Redis.current.set("funding_order_by_#{params[:out_trade_no]}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 1}) )
        ChangeFundingStatusWorker.perform_async(eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}")), 'web', :change_funding_status)
      end
      render :text => 'success'
    else
      render :text => 'error'
    end
  end

  def wx_order_status
    @order = Shop::FundingOrder.find_by(order_no: params[:id])
    render json: { status: @order.status }, status: 200
  end

  def wx_pay_direct_notify
    result = Hash.from_xml(request.body.read)["xml"]

    if WxPay::Sign.verify?(result)
      if result['result_code'] == 'SUCCESS'
        @order = eval(Redis.current.get("funding_order_by_#{result['out_trade_no']}"))
        Redis.current.set("funding_order_by_#{result['out_trade_no']}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 2}) )
        ChangeFundingStatusWorker.perform_async(eval(Redis.current.get("funding_order_by_#{result['out_trade_no']}")), 'web', :change_funding_status)
      end
      render :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
    else
      render :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
    end
  end

  #处理支付方式 跳转对应界面
  def settlement
    @order = Shop::FundingOrder.find_by(order_no: params[:id])
    return redirect_to :back, alert: "订单还在队列中排队，稍后在进行支付哦" unless @order
    ticket_type = Shop::TicketType.find_by(id: @order.shop_ticket_type_id)
    return redirect_to shop_funding_orders_path, alert: "您已经支付过了，不要乱花钱哦" if @order.status == 'paid'
    return redirect_to :back, alert: "订单已过期，请重新下单" if @order.status == 'deleted'
    return redirect_to shop_funding_orders_path, alert: "订单已经取消" if @order.status == 'canceled'
    return redirect_to shop_funding_orders_path, alert: "您已经支付过了，不要乱花钱哦" unless @order.can_order_pay_and_cancel?
    array_status = ticket_type.created_order_options(@order, @order.quantity, @current_user, can_equal=false)
    return redirect_to :back, alert: array_status[1] if !array_status[0] #判断是否能够购买

    bank = params[:banks]
    @order.update(platform: 'web') unless @order.platform == 'web'
    @order = eval(Redis.current.get("funding_order_by_#{params[:id]}"))
    Redis.current.set("funding_order_by_#{params[:id]}", @order )

    if bank == 'alipay'
      alipay_direct_url = Shop::OrderHelper.alipay_direct_url(@order.merge(web_type: params[:web_type] || 'web'))
      if alipay_direct_url.present?
        return redirect_to alipay_direct_url
      else
        return redirect_to :back, alert: "您的支付在支付方可能超时啦, 请重新下单吧"
      end
    elsif bank == 'wx_pay'
      wx_pay_direct_url = Shop::OrderHelper.wx_pay_direct_url(@order, request.remote_ip == "::1" ? '127.0.0.1' : request.remote_ip)
      if wx_pay_direct_url.present?
        return redirect_to wx_pay_direct_url
      else
        return redirect_to :back, alert: "微信服务器出了一些问题，重试一下吧！"
      end
    else
      alipay_direct_url = Shop::OrderHelper.alipay_direct_url(@order)
      if alipay_direct_url.present?
        return redirect_to alipay_direct_url
      else
        return redirect_to :back, alert: "您的支付在支付方可能超时啦, 请重新下单吧"
      end
    end
  end

  #微信二维码支付页面
  def wx_qr_code
    order = Shop::FundingOrder.find_by(order_no: params[:id])
    return redirect_to shop_funding_orders_path, alert: "您已经支付过了，不要乱花钱哦" unless order.can_order_pay_and_cancel?
  end

  private

  def shop_funding_order_params
    params.require(:shop_funding_order)
      .permit(:id, :guide, :title, :shop_category, :description,
       star_list: [])
  end

end
