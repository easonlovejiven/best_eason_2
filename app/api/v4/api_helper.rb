module V4
  module APIHelper
    APPS = {'owhat_app' => 'OTjnsYw76IR98', 'owhat_web' => 'Yw76IR98jnsOT'}
    def check_sign
      @app = APPS[params[:app_key]]
      if @app
        user_token = ''
        if params[:app_key] == 'owhat_app' && params.has_key?(:uid) && params[:uid].present?
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

    def logger_format(data)
      data = {data: data} unless data.class == Hash
      data.merge!({uid: params[:uid], from_client: params[:from_client], app_version: params[:app_version], api_version: 'v4'})
    end

    def params_hash
      params_hash = params.to_hash.merge!(user_id: @current_user.id).reject{ |k, v| k == "format" || k == 'uid' || k == "app_key" || k == "route_info" || k == "method" || k == "path" || k == "sign" || k == "app_version" || k == "sign" || k == "from_client" || k == "device_id" || k == "device_models" || k == "manufacturer" || k == "system_version" }
    end
  end
end
