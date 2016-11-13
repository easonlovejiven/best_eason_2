module Shop
  module OrderHelper
    extend ActiveSupport::Concern

    #查询微信支付是否成功 app端的查询接口 ， 网站端绑定的公众号的
    def self.search_wxpay_status out_trade_no, shop_category, from
      setting = Rails.application.secrets.weixin_app.try(:[], "payment") || {}
      nonce_str = SecureRandom.hex(16)
      sign = self.wxpay_status_sign out_trade_no, nonce_str, setting
      xml = "<xml>
        <appid><![CDATA[#{setting["appid"]}]]></appid>
        <mch_id><![CDATA[#{setting["mch_id"]}]]></mch_id>
        <nonce_str><![CDATA[#{nonce_str}]]></nonce_str>
        <out_trade_no><![CDATA[#{out_trade_no}]]></out_trade_no>
        <sign><![CDATA[#{sign}]]></sign>
      </xml>"
      r = RestClient.post 'https://api.mch.weixin.qq.com/pay/orderquery', xml , {:content_type => :xml}
      return_hash = Hash.from_xml(r)
      Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>return_hash: #{return_hash}"
      return ['fail', return_hash['xml']['return_msg']] if return_hash['xml']['return_code'] == 'FAIL'
      return_hash = return_hash['xml']
      if return_hash['return_code'] == 'SUCCESS' && return_hash['result_code'] == 'SUCCESS'
        paid_at = return_hash['time_end']
        if return_hash['trade_state'] == 'SUCCESS'
          unless shop_category == "Shop::Funding"
            @order = eval(Redis.current.get("order_by_#{return_hash['out_trade_no']}"))
            Redis.current.set("order_by_#{return_hash['out_trade_no']}", @order.update(status: 2).merge!({paid_at: paid_at, pay_type: 2}) )
            ChangeOrderStatusWorker.perform_async(eval(Redis.current.get("order_by_#{return_hash['out_trade_no']}")), from, :change_order_status)
          else
            @order = eval(Redis.current.get("funding_order_by_#{return_hash['out_trade_no']}"))
            Redis.current.set("funding_order_by_#{return_hash['out_trade_no']}", @order.update(status: 2).merge!({paid_at: paid_at, pay_type: 2}) )
            ChangeFundingStatusWorker.perform_async(eval(Redis.current.get("funding_order_by_#{return_hash['out_trade_no']}")), from, :change_funding_status)
          end
          return ['success', '订单支付成功']
        else
          return ['fail', '订单支付未成功']
        end
      end
    end

    def self.wxpay_status_sign out_trade_no, nonce_str, setting
      s = {
        appid: setting["appid"],
        mch_id: setting["mch_id"],
        nonce_str: nonce_str,
        out_trade_no: out_trade_no
      }.sort.map{ |key, value| "#{key}=#{value}" }.join('&')
      s = s+"&key=#{setting["wx_key"]}"
      Digest::MD5.hexdigest(s).upcase
    end

    def self.wxpay_web_status_sign out_trade_no, nonce_str, setting
      s = {
        appid: setting["appid"],
        mch_id: setting["mch_id"],
        nonce_str: nonce_str,
        out_trade_no: out_trade_no,
      }.sort.map{ |key, value| "#{key}=#{value}" }.join('&')
      s = s+"&key=#{setting["key"]}"
      Digest::MD5.hexdigest(s).upcase
    end

    #支付宝支付
    def self.alipay_direct_url(params_hash)
      if params_hash[:expired_at].present?
        minutes = params_hash[:expired_at].to_time - Time.now
        min = minutes <= 0 ? 0 : (minutes/60).to_i
      else
        minutes = (params_hash[:created_at].to_time + 20.minutes) - Time.now
        min = minutes <= 0 ? 0 : (minutes/60).to_i
      end
      return if min < 1
      ticket_type = Shop::TicketType.find(params_hash[:shop_order].first[:ticket_type_id])
      task = ticket_type.task
      if task.class.name == "Shop::Funding"
        return_url = Rails.application.routes.url_helpers.success_shop_funding_order_url(params_hash[:order_no])
        notify_url = Rails.application.routes.url_helpers.alipay_direct_notify_shop_funding_order_url(params_hash[:order_no])
      else
        return_url = Rails.application.routes.url_helpers.success_shop_order_url(params_hash[:order_no])
        notify_url = Rails.application.routes.url_helpers.alipay_direct_notify_shop_order_url(params_hash[:order_no])
      end
      address = Core::Address.find_by(id: params_hash[:address_id].to_i)
      Alipay::Service.send(
        params_hash[:web_type] == "phone" ? :create_direct_pay_by_user_wap_url : :create_direct_pay_by_user_url,
        {
          :out_trade_no      => params_hash[:order_no],
          :total_fee         => params_hash[:sum_fee].to_s,
          :discount          => '0',
          :subject           => params_hash[:shop_order].map{ |o| Shop::TicketType.find(o[:ticket_type_id]).task.title }.join(', ') || 'Owhat 订单支付',
          :logistics_type    => 'DIRECT',
          :logistics_fee     => '0',
          :logistics_payment => 'SELLER_PAY',
          :return_url        => return_url,
          :notify_url        => notify_url,
          :receive_name      => address.try(:addressee),
          :receive_mobile    => address.try(:mobile),
          :it_b_pay          => "#{min}m"
        }.reject {|k,v| v.blank? }
      )
    end

    #微信支付
    def self.wx_pay_direct_url params_hash, remote_ip
      return_params = self.initialize_wx_payment(params_hash, remote_ip)
      params = return_params[0]
      task = return_params[1]
      return unless params
      r = WxPay::Service.invoke_unifiedorder(params)
      return if r["return_code"] != "SUCCESS" || r["return_msg"] != "OK"
      code, result, response_headers = Rails.cache.fetch("wx_image_#{task.class.name}_#{params_hash[:order_no]}", expires_in: 15.minutes) do
        qrcode_png = RQRCode::QRCode.new( r["code_url"], :size => 5, :level => :h ).to_img.resize(200, 200).save("public/uploads/tmp/#{params_hash[:order_no]}_#{Time.now.to_i.to_s}.png")
        return unless qrcode_png.present?
        code, result, response_headers = ApplicationHelper.upload_image_to_qiniu "#{Rails.application.secrets.qiniu_host_name}", "#{params_hash[:order_no]}_#{Time.now.to_i.to_s}"
      end
      if code == 200
        unless task.class.name == "Shop::Funding"
          return Rails.application.routes.url_helpers.wx_qr_code_shop_order_url(id: params_hash[:order_no], url: "http://#{Rails.application.secrets.qiniu_host}/#{result["key"]}" , shop_order: params_hash[:shop_order], title: params_hash[:shop_order].map{ |o| Shop::TicketType.find(o[:ticket_type_id]).task.title }.join(', ') || 'Owhat 订单支付', sum_fee: params_hash[:sum_fee].to_f)
        else
          return Rails.application.routes.url_helpers.wx_qr_code_shop_funding_order_url(id: params_hash[:order_no], url: "http://#{Rails.application.secrets.qiniu_host}/#{result["key"]}" , shop_order: params_hash[:shop_order], title: params_hash[:shop_order].map{ |o| Shop::TicketType.find(o[:ticket_type_id]).task.title }.join(', ') || 'Owhat 应援订单支付', sum_fee: params_hash[:sum_fee].to_f)
        end
      else
        return
      end
    rescue Exception => e
      return
    end

    def self.initialize_wx_payment(params_hash, remote_ip)
      if params_hash[:expired_at].present?
        minutes = params_hash[:expired_at].to_time - Time.now
        min = minutes <= 0 ? 0 : (minutes/60).to_i
      else
        minutes = (params_hash[:created_at].to_time + 20.minutes) - Time.now
        min = minutes <= 0 ? 0 : (minutes/60).to_i
      end
      return if min < 1
      ticket_type = Shop::TicketType.find(params_hash[:shop_order].first[:ticket_type_id])
      task = ticket_type.task
      if task.class.name == "Shop::Funding"
        notify_url = Rails.application.routes.url_helpers.wx_pay_direct_notify_shop_funding_order_url(params_hash[:order_no])
      else
        notify_url = Rails.application.routes.url_helpers.wx_pay_direct_notify_shop_order_url(params_hash[:order_no])
      end
      initialize_title = params_hash[:shop_order].map{ |o| task.title }.join(', ')
      title = initialize_title.size > 60 ? "Owhat 订单支付#{params_hash[:shop_order].map{|o| o[:ticket_type_id]}}" : initialize_title.gsub(/[<>]/, "")
      params = {
        :body => title,
        :out_trade_no => params_hash[:order_no],
        :total_fee => (params_hash[:sum_fee].to_f * 100).to_i,
        :spbill_create_ip => remote_ip,
        :notify_url => notify_url,
        :trade_type => 'NATIVE',
      }
      params.merge!({:time_expire => params_hash[:expired_at].to_time.to_s(:number)}) if params_hash[:expired_at].present?
      [params, task]
    end

    def self.get_weixin_paid_info(platform, order)
      total_fee = order.class.name == "Shop::Order" ? order.total_fee.to_f.round(2) : order.payment.to_f.round(2)
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
      return_hash = return_hash['xml'] || {}
      Rails.logger.info "get_weixin_paid_info #{platform} #{order.order_no}--->>return #{return_hash}"
      weixin_total_fee = (return_hash['total_fee'] || 0).to_f.round(2)
      {is_exist: return_hash['result_code'] == 'SUCCESS', is_paid: return_hash['trade_state'] == 'SUCCESS', free_is_right: weixin_total_fee == total_fee * 100}
    end

    def self.get_alipay_paid_info(order)
      total_fee = order.class.name == "Shop::Order" ? order.total_fee.to_f.round(2) : order.payment.to_f.round(2)
      xml = Alipay::Service.single_trade_query(out_trade_no: order.order_no)
      result = Hash.from_xml(xml)
      return_hash = result['alipay'] || {}
      Rails.logger.info "get_alipay_paid_info #{order.order_no}--->>return #{return_hash}"
      trade = (return_hash["response"] || {})["trade"]
      trade_status = (trade || {})['trade_status'].to_s
      alipay_total_fee = ((trade || {})['total_fee'] || 0).to_f.round(2)
      {is_exist: return_hash["is_success"] == "T", is_paid: ['TRADE_SUCCESS', 'TRADE_FINISHED'].include?(trade_status), free_is_right: alipay_total_fee == total_fee}
    end

    def self.cancel_alipay_paid(order)
      xml = Alipay::Service.close_trade(out_order_no: order.order_no)
      result = Hash.from_xml(xml)
      Rails.logger.info "cancel_alipay_paid #{order.order_no}--->>return #{result}"
      (result["alipay"] || {})["is_success"] == "T"
    end

    def self.cancel_weixin_paid(platform, order)
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
      r = RestClient.post 'https://api.mch.weixin.qq.com/pay/closeorder', xml , {:content_type => :xml}
      return_hash = Hash.from_xml(r)
      Rails.logger.info "cancel_weixin_paid #{platform} #{order.order_no}--->>return #{return_hash}"
      (return_hash['xml'] || {})['result_code'] == "SUCCESS"
    end

  end
end
