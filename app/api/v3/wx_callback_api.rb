# encoding:utf-8
module V3
  class WxCallbackApi < Grape::API
    format :xml

    desc "微信回调接口"
    post :shop_product_wx_back do
      Rails.logger.info "---------------------------11111111111111111111111111111111微信支付回调psarams: #{params}"
      result = Hash.from_xml(request.body.read)["xml"]
      if WxPay::Sign.verify?(result)
        if result['result_code'] == 'SUCCESS'
          @order = eval(Redis.current.get("order_by_#{result['out_trade_no']}"))
          Redis.current.set("order_by_#{result['out_trade_no']}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db)}) )
          ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{result['out_trade_no']}")), 'web', :change_order_status)
          CoreLogger.info(logger_format(api: "shop_product_wx_back", order_id: @order.try(:id)))
        end
        return :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
      else
        return :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
      end
    end

    desc "微信回调接口"
    post :shop_funding_wx_back do
      Rails.logger.info "---------------------------11111111111111111111111111111111微信支付回调psarams: #{params}"
      result = Hash.from_xml(request.body.read)["xml"]

      if WxPay::Sign.verify?(result)
        if result['result_code'] == 'SUCCESS'
          @order = eval(Redis.current.get("funding_order_by_#{result['out_trade_no']}"))
          Redis.current.set("funding_order_by_#{result['out_trade_no']}", @order.update(status: 2).merge!({paid_at: Time.now.to_s(:db), pay_type: 2}) )
          ChangeFundingStatusWorker.perform_async(eval(Redis.current.get("funding_order_by_#{result['out_trade_no']}")), 'web', :change_order_status)
          CoreLogger.info(logger_format(api: "shop_funding_wx_back", order_id: @order.try(:id)))
        end
        return :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
      else
        return :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
      end
    end

  end
end
