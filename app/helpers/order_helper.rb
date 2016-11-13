module OrderHelper
  def shop_order_scan order, ticket_type_ids = []
    total_fee = order.class.name == "Shop::Order" ? order.total_fee.to_f.round(2) : order.payment.to_f.round(2)
    if total_fee > 0
      return_hash = get_wechat_options order, order.platform
      if order.pay_type == 1 || return_hash['xml']['return_code'] == 'FAIL' || return_hash['xml']['result_code'] == 'FAIL' || return_hash['xml']['err_code'] == 'ORDERNOTEXIST' || return_hash['xml']['trade_state'] == 'NOTPAY'
        xml = Alipay::Service.single_trade_query(out_trade_no: order.order_no)
        result = Hash.from_xml(xml)
        if result["alipay"]["is_success"] == "T"
          p "开始查询#{order.order_no}的支付宝状态"
          trade = result["alipay"]["response"]["trade"]
          if ['TRADE_SUCCESS', 'TRADE_FINISHED'].include?(trade['trade_status'].to_s) && trade['total_fee'].to_f.round(2) == total_fee
            unless order.status == 'paid'
              ticket_type_ids = change_order_paid order, '支付宝', ticket_type_ids, trade
            end
          else
            if order.platform == 'web'
              return_hash = get_wechat_options order, 'app'
            else
              return_hash = get_wechat_options order, 'web'
            end
            return_hash = return_hash['xml']
            if return_hash['return_code'] == 'SUCCESS' && return_hash['result_code'] == 'SUCCESS'
              paid_at = return_hash['time_end']
              if return_hash['trade_state'] == 'SUCCESS'
                unless order.status == 'paid'
                  ticket_type_ids = change_order_paid order, '微信', ticket_type_ids, {'gmt_payment' => paid_at}
                end
              else
                unless order.status == 'deleted'
                  ticket_type_ids = change_order_delete order, '微信', ticket_type_ids
                end
              end
            else
              unless order.status == 'deleted'
                ticket_type_ids = change_order_delete order, '支付宝', ticket_type_ids
              end
            end
          end
        else
          if order.platform == 'web'
            return_hash = get_wechat_options order, 'app'
          else
            return_hash = get_wechat_options order, 'web'
          end
          return_hash = return_hash['xml']
          if return_hash['return_code'] == 'SUCCESS' && return_hash['result_code'] == 'SUCCESS'
            paid_at = return_hash['time_end']
            if return_hash['trade_state'] == 'SUCCESS'
              unless order.status == 'paid'
                ticket_type_ids = change_order_paid order, '微信', ticket_type_ids, {'gmt_payment' => paid_at}
              end
            else
              unless order.status == 'deleted'
                ticket_type_ids = change_order_delete order, '微信', ticket_type_ids
              end
            end
          else
            unless order.status == 'deleted'
              ticket_type_ids = change_order_delete order, '支付宝', ticket_type_ids
            end
          end
        end

      else
        p "开始查询#{order.order_no}的微信状态"
        return_hash = return_hash['xml']
        if return_hash['return_code'] == 'SUCCESS' && return_hash['result_code'] == 'SUCCESS'
          paid_at = return_hash['time_end']
          if return_hash['trade_state'] == 'SUCCESS'
            unless order.status == 'paid'
              ticket_type_ids = change_order_paid order, '微信', ticket_type_ids, {'gmt_payment' => paid_at}
            end
          else
            if order.platform == 'web'
              return_hash = get_wechat_options order, 'app'
            else
              return_hash = get_wechat_options order, 'web'
            end
            return_hash = return_hash['xml']
            if return_hash['return_code'] == 'SUCCESS' && return_hash['result_code'] == 'SUCCESS'
              paid_at = return_hash['time_end']
              if return_hash['trade_state'] == 'SUCCESS'
                unless order.status == 'paid'
                  ticket_type_ids = change_order_paid order, '微信', ticket_type_ids, {'gmt_payment' => paid_at}
                end
              else
                unless order.status == 'deleted'
                  ticket_type_ids = change_order_delete order, '微信', ticket_type_ids
                end
              end
            end

          end
        end
      end
    end

    return ticket_type_ids
  end

  private

  def get_wechat_options order, platform
    if platform == 'web'
      setting = Rails.application.secrets.weixin.try(:[], "payment") || {}
      nonce_str = SecureRandom.hex(16)
      sign = Shop::OrderHelper.wxpay_web_status_sign order.order_no, nonce_str, setting
    else
      setting = Rails.application.secrets.weixin_app.try(:[], "payment") || {}
      nonce_str = SecureRandom.hex(16)
      sign = Shop::OrderHelper.wxpay_status_sign order.order_no, nonce_str, setting
    end
    xml = "<xml>
      <appid><![CDATA[#{setting["appid"]}]]></appid>
      <mch_id><![CDATA[#{setting["mch_id"]}]]></mch_id>
      <nonce_str><![CDATA[#{nonce_str}]]></nonce_str>
      <out_trade_no><![CDATA[#{order.order_no}]]></out_trade_no>
      <sign><![CDATA[#{sign}]]></sign>
    </xml>"
    r = RestClient.post 'https://api.mch.weixin.qq.com/pay/orderquery', xml , {:content_type => :xml}
    return_hash = Hash.from_xml(r)
  end

  def change_order_paid order, status, ticket_type_ids, trade
    pay_type = status == '微信' ? 2 : 1
    ActiveRecord::Base.transaction do
      if order.class.name == "Shop::Order"
        order.order_items.each do |item|
          p "#{Time.now}------------#{status}更改商品活动订单状态>item: #{item.order_no}"
          p "#{Time.now}————————> #{status}价格商品活动子订单id: #{item.shop_ticket_type_id} 已存入"
          ticket_type_ids << item.shop_ticket_type_id
          item.update!(status: 2, paid_at: trade['gmt_payment'], pay_type: pay_type, updated_paid_at: Time.now)
        end
        order.update!(status: 2, paid_at: trade['gmt_payment'], pay_type: pay_type, updated_paid_at: Time.now)
      else
        p "#{Time.now}------------#{status}更改应援订单状态>item: #{order.order_no}"
        p "#{Time.now}————————> #{status}价格商品活动子订单id: #{order.shop_ticket_type_id} 已存入"
        ticket_type_ids << order.shop_ticket_type_id
        order.update!(status: 2, paid_at: trade['gmt_payment'], pay_type: pay_type, updated_paid_at: Time.now)
      end
    end
    return ticket_type_ids
  end

  def change_order_delete order, status, ticket_type_ids
    p "#{Time.now}---------->#{status}#{order.class.name}: #{order.platform}删除订单和原状态不符 #{order.order_no}"
    if order.class.name == "Shop::Order"
      order.order_items.find_each do |item|
        ticket_type_ids << item.shop_ticket_type_id
        p "#{Time.now}————————> #{status}价格商品活动子订单id: #{item.shop_ticket_type_id} 已存入"
      end
      ActiveRecord::Base.transaction do
        order.order_items.each do |item|
          p "#{Time.now}————————> #{status}#{order.class.name}:价格id: #{item.shop_ticket_type_id} 开始更改"
          item.update!(status: -1)
        end
        order.update!(status: -1)
      end
    else
      ticket_type_ids << order.shop_ticket_type_id
      p "#{Time.now}————————> #{status}应援owhat_product价格id: #{order.shop_ticket_type_id} 已存入"
      order.update(status: -1)
    end
    return ticket_type_ids
  end
end
