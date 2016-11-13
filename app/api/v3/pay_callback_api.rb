# encoding:utf-8
module V3
  class PayCallbackApi < Grape::API
    format :txt

    desc "支付宝商品活动购买成功回调接口"
    post :shop_product_alipay_back do
      Rails.logger.info "-----------------------------> 支付回调参数：#{params}"
      order = Shop::Order.find_by(order_no: params[:out_trade_no])
      return 'fail' if order.status && order.status == 'paid'
      if params[:trade_status] == "TRADE_SUCCESS"
        order.update(question_memo: "钱数对应不上 支付宝支付：#{params[:total_fee]}") unless params[:total_fee].to_f == order.total_fee.to_f
        @order = eval(Redis.current.get("order_by_#{params[:out_trade_no]}"))
        Redis.current.set("order_by_#{params[:out_trade_no]}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 1 }) )
        ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{params[:out_trade_no]}")), 'iOS', :change_order_status) #ios 或者 android 可能已经存在
        CoreLogger.info(logger_format(api: "shop_product_alipay_back", order_id: order.try(:id)))
        return 'success'
      end
    end

    desc "应援购买成功回调接口"
    params do
      requires :order_no, type: String
      requires :paid_at, type: DateTime
      requires :pay_type, type: String
    end
    post :shop_funding_alipay_back do
      Rails.logger.info "-----------------------------> 支付回调参数：#{params}"
      order = Shop::FundingOrder.find_by(order_no: params[:out_trade_no])
      return 'fail' if order.status && order.status == 'paid'
      if params[:trade_status] == "TRADE_SUCCESS"
        order.update(question_memo: "钱数对应不上 支付宝支付：#{params[:total_fee]}") unless params[:total_fee].to_f == order.payment.to_f
        @order = eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}"))
        Redis.current.set("funding_order_by_#{params[:out_trade_no]}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 1}) )
        ChangeFundingStatusWorker.perform_async(eval(Redis.current.get("funding_order_by_#{params[:out_trade_no]}")), 'iOS', :change_funding_status)
        CoreLogger.info(logger_format(api: "shop_funding_alipay_back", order_id: order.try(:id)))
        return 'success'
      end
    end

  end
end
