module V4
  class PayApi < Grape::API

    format :json

    before do
      check_sign
    end

    desc "支付宝android参数获取"
    params do
      requires :type, type: String
      requires :order_no, type: String
      requires :payment, type: Float
    end
    get :get_alipay_order_info do
      order_no = params[:order_no]
      type = params[:type]
      if type == "shop_fundings"
        notify_url = "http://#{params[:from_client] == "iOS" ? 'm' : 'i'}.owhat.cn/v3/shop_funding_alipay_back.json"
      else
        notify_url = "http://#{params[:from_client] == "iOS" ? 'm' : 'i'}.owhat.cn/v3/shop_product_alipay_back.json"
      end
      data = Alipay::Mobile::Service.mobile_securitypay_pay_string({
        out_trade_no: order_no,
        notify_url: notify_url,
        subject: "O!what订单#{order_no}",
        total_fee: "#{params[:total_fee].to_f.round(2)}",
        body: ''}, {sign_type: "RSA", key: Settings.alipay["private_key"]}
      )
      ret = { data: {pay_info: data} }
      success(ret)

    end
  end
end
