module V3
  module APIHelper
    APPS = {'owhat_app' => 'OTjnsYw76IR98'}
    def check_sign
      @app = APPS[params[:app_key]]
      if @app
        user_token = ''
        if params[:app_key] == 'owhat_app' && params.has_key?(:uid) && params[:uid].present?
          error!("更新版本吧，您的参数传的出现错误！", 460) if params[:uid].to_i == 0
          @current_account = Core::Account.find_by(id: params[:uid])
          @current_user = @current_account.try(:user)
          @current_user.login_today('app', {
            ip_address: (env['action_dispatch.remote_ip'] || '').to_s,
            client: params[:from_client],
            device_id: params[:device_id],
            device_models: params[:device_models],
            manufacturer: params[:manufacturer],
            system_version: params[:system_version]
          })
          user_token = @current_account.try(:login_salt) || @current_account.try(:reset_login_salt)
        end

        sign = sign_params(params, @app, user_token)

        if sign != params[:sign]
          Rails.logger.info "#{sign} - #{params[:sign]}"
          error!('认证失败', 401)
        end

        if params[:app_key] == 'owhat_app'
          if !params[:app_version] || params[:app_version] < '2.5.5'
            error!('版本号不匹配，请更新到最新版', 450)
          end
        end
      else
        error!('认证失败', 401)
      end
    end

    def success(result = {})
      status(200)
      ret = {:status => true, :time => Time.now.to_i, :version => '3.0'}.merge(result)

      present(ret)
    end

    def fail(error_code, error = nil)
      if error_code != 0
        error_msg = ERROR["errors"][error_code]
      else
        error_msg = error
      end
      ret = {:status => false, :error => error_msg, :error_code => error_code, :time => Time.now.to_i, :version => '3.0'}

      present(ret)
    end

    def fail_msg(error_code, error = nil)
      if error_code != 0
        error_msg = ERROR["errors"][error_code]
      else
        error_msg = error
      end
      ret = {:status => false, :error => error_msg, :error_code => error_code, :time => Time.now.to_i, :version => '3.0'}

      present(ret)
    end

    def sign_params(params, app_secret, user_token = '')
      data_s = params.map do |k, v|
        next if v.is_a? Hash
        next if v.is_a? Array
        unless  ['route_info', 'method', 'path', 'sign', 'format'].include?(k)
          "#{k}=#{v.to_s}"
        end
      end.compact.sort.join('&')
      Rails.logger.info("++++++++++++++++++>data_s: #{data_s} ----------------->params: #{params}")
      sign = Digest::MD5.hexdigest("#{data_s}#{app_secret}#{user_token}").downcase
    end

    def database_transaction
      begin
        ActiveRecord::Base.transaction do
          yield
        end
        true
      rescue => e
        Rails.logger.error %[#{e.class.to_s} (#{e.message}):\n\n #{e.backtrace.join("\n")}\n\n]
        false
      end
    end

    def params_hash
      params_hash = params.to_hash.merge!(user_id: @current_user.id).reject{ |k, v| k == "format" || k == 'uid' || k == "app_key" || k == "route_info" || k == "method" || k == "path" || k == "sign" || k == "app_version" || k == "sign" || k == "from_client" || k == "device_id" || k == "device_models" || k == "manufacturer" || k == "system_version" }
    end

    def version_compare
      if params[:from_client] == 'Android'
        Gem::Version.new(params[:app_version]) >= Gem::Version.new('3.1')
      else
        Gem::Version.new(params[:app_version]) >= Gem::Version.new('3.24')
      end
    end

    def get_wxpay_sign body, nonce_str, out_trade_no, total_fee, notify_url, spbill_create_ip, setting
      s={appid: setting["appid"], mch_id: setting["mch_id"],
        body: body, nonce_str: nonce_str, out_trade_no: out_trade_no,
        total_fee: total_fee, spbill_create_ip: spbill_create_ip,
        notify_url: notify_url,
        trade_type: "APP" }.sort.map{ |key, value| "#{key}=#{value}" }.join('&')
      s=s+"&key=#{setting["wx_key"]}"
      Digest::MD5.hexdigest(s).upcase
    end

    def wxpay_v3_xml nonce_str, body, out_trade_no, total_fee, notify_url, spbill_create_ip
      setting = Rails.application.secrets.weixin_app.try(:[], "payment") || {}
      sign = get_wxpay_sign body, nonce_str, out_trade_no, total_fee, notify_url, spbill_create_ip, setting
      xml = "<xml>
        <appid><![CDATA[#{setting["appid"]}]]></appid>
        <body><![CDATA[#{body}]]></body>
        <mch_id><![CDATA[#{setting["mch_id"]}]]></mch_id>
        <nonce_str><![CDATA[#{nonce_str}]]></nonce_str>
        <notify_url><![CDATA[#{notify_url}]]></notify_url>
        <out_trade_no><![CDATA[#{out_trade_no}]]></out_trade_no>
        <spbill_create_ip><![CDATA[#{spbill_create_ip}]]></spbill_create_ip>
        <total_fee>#{total_fee}</total_fee>
        <trade_type><![CDATA[APP]]></trade_type>
        <sign><![CDATA[#{sign}]]></sign>
      </xml>"
      return xml
    end

    def return_wxpay_sign timestamp, nonce_str, prepay_id
      setting = Rails.application.secrets.weixin_app.try(:[], "payment") || {}
      wx_params = {appid: setting["appid"], partnerid: setting["mch_id"], prepayid: prepay_id, timestamp: timestamp, noncestr: nonce_str, package: "Sign=WXPay"}.sort.map{ |key, value| "#{key}=#{value}" }.join('&')
      wx_params = wx_params+"&key=#{setting["wx_key"]}"
      pay_sign = Digest::MD5.hexdigest(wx_params).upcase
    end

    def logger_format(data)
      data = {data: data} unless data.class == Hash
      data.merge!({uid: params[:uid], from_client: params[:from_client], app_version: params[:app_version], api_version: 'v3'})
    end

  end
end
