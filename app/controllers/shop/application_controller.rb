class Shop::ApplicationController < Home::ApplicationController
  include ApplicationHelper
  layout 'home/application'
  before_filter :verify_user, only: [:new]
  # before_filter :get_tasks, only:[:show]
  before_filter :get_users, only:[:show, :index]
  def shop_product_wx_back
    Rails.logger.info "---------------------------微信商品订单支付回调接口params: #{params}"
    result = Hash.from_xml(request.body.read)["xml"]
    if WxPay::Sign.verify?(result)
      Rails.logger.info "---------------------------微信商品订单支付回调接口result: #{result}"
      if result['result_code'] == 'SUCCESS'
        @order = eval(Redis.current.get("order_by_#{result['out_trade_no']}"))
        Redis.current.set("order_by_#{result['out_trade_no']}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 2, wx_total_fee: result['total_fee']}) )
        ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{result['out_trade_no']}")), 'web', :change_order_status)
        CoreLogger.info(controller: "Shop::Application", action: 'shop_product_wx_back', order_id: @order.try(:id), current_user: @current_user.try(:id))
      end
      return render :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
    else
      return render :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
    end
  end

  def shop_funding_wx_back
    Rails.logger.info "---------------------------微信应援订单支付回调接口params: #{params}"
    result = Hash.from_xml(request.body.read)["xml"]

    if WxPay::Sign.verify?(result)
      Rails.logger.info "---------------------------微信商品订单支付回调接口result: #{result}"
      if result['result_code'] == 'SUCCESS'
        @order = eval(Redis.current.get("funding_order_by_#{result['out_trade_no']}"))
        Redis.current.set("funding_order_by_#{result['out_trade_no']}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 2, wx_total_fee: result['total_fee']}) )
        ChangeFundingStatusWorker.perform_async(eval(Redis.current.get("funding_order_by_#{result['out_trade_no']}")), 'web', :change_funding_status)
        CoreLogger.info(controller: "Shop::Application", action: 'shop_funding_wx_back', order_id: @order.try(:id), current_user: @current_user.try(:id))
      end
      return render :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
    else
      return render :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
    end
  end

  def fenqile_success
    # @order = Shop::Order.find_by(id: params[:id])
    Rails.logger.info "---------------------------微信应援订单支付回调接口params: #{params}"
    @order = eval(Redis.current.get("order_by_#{result['out_trade_no']}"))
    Rails.logger.info "-------#{params}----"
    raise "没有该订单" if @order.nil?
    unless @order[:status] == 'paid'
      sign = Digest::MD5.hexdigest(params.slice(:result, :res_info, :partner_id, :merch_id, :c_merch_id, :trans_id, :amount, :out_trade_no, :trans_status, :payment_type, :attach, :subject, :body, :currency_type).reject{|k, v| v.blank? }.sort.map{|k,v|"#{k}=#{v}"}.join("&")+ "&key=#{Rails.application.secrets.fenqile['key']}")
      if params[:result] == 1 && params[:partner_id] == Rails.application.secrets.fenqile["appid"] && params[:sign] == sign
        @order = eval(Redis.current.get("order_by_#{@order.order_no}"))
        Redis.current.set("order_by_#{result['out_trade_no']}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 4}) )
        ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{params[:out_trade_no]}")), 'web', :change_order_status)
        CoreLogger.info(controller: "Shop::Application", action: 'fenqile_success', order_id: @order.try(:id), current_user: @current_user.try(:id))
        render text: 'success'
      else
        render text: 'error'
      end
    end
  end

  private
  def authorized?
    super
    return true if %w[show shop_product_wx_back shop_funding_wx_back].include?(params[:action])
    !!@current_user
  end

  def verify_user
    raise '没有权限' unless @current_user.verified?
  end

  # def get_tasks
  #   Rails.cache.fetch("get_aside_tasks", :expires_in => 1.hours) do
  #     @tasks = Shop::Task.events.where(user_id: publish_user.id).order(position: :desc, created_at: :desc).limit(3)
  #   end
  # end

  def get_users
    @get_users = Rails.cache.fetch("get_aside_users", :expires_in => 1.hours) do
      if @current_user.present?
        Core::User.active.where("verified = 1 AND id != #{@current_user.id}").order(position: :desc, created_at: :desc).limit(10).sample(3)
      else
        Core::User.active.where("verified = 1").order(position: :desc, created_at: :desc).limit(10).sample(3)
      end
    end
  end
end
