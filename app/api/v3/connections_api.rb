module V3
  class ConnectionsApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      optional :uid, type: String
      requires :site, type: String
      requires :identifier, type: String
      requires :token, type: String
      optional :name, type: String
      optional :pic, type: String
      optional :expired_at, type: DateTime
      optional :data, type: Hash
    end
    post :conection_callback do
      return fail(0, "参数错误") unless %w(qq wechat weibo).include?(params[:site].to_s)
      # android 已经登陆过新的无问题第三方登陆版本 再来用正确的账号登陆老的版本
      connection = Core::Connection.active.find_or_initialize_by(site: params[:site], identifier: params[:identifier])
      connection.attributes = {
        token: params[:token],
        name: params[:name].to_s.strip_emoji,
        pic: params[:pic],
        expired_at: params[:site] == 'weibo' ? (Time.now + 29.days) : params[:expired_at],
        data: params[:data].to_s.strip_emoji
      }
      succeed = if @current_account
        if connection.id
          if connection.account.present? && (connection.account.email.present? || connection.account.phone.present?)
            return fail(0, "该第三方账号已绑定主账号，可直接用该第三方账号登陆")
          elsif connection.account.present? && connection.account.email.blank? && connection.account.phone.blank?
            return fail(0, "系统检测到你已有该第三方账户记录，建议你按照以下操作 1.退出当前主账号， 2.用第三方账户登陆， 3.用该第三方账号绑定你退出的主账号。来绑定主账号。")
          else
            return fail(0, "该账号已绑定")
          end

        end
        connection.account = @current_account
        connection.save
      else
        database_transaction do
          connection.save!
          if connection.account
            account = connection.account
          else
            Rails.logger.info("---------#{env["REMOTE_ADDR"]}-----------")
            account = Core::Account.new
            account.attributes = { ip_address: env["REMOTE_ADDR"], login_salt: account.reset_login_salt, client: params[:from_client]}
            account.save!
            user = Core::User.create!(id: account.id, name: connection.name.blank? ? "O星人#{SecureRandom.urlsafe_base64(8)}" : connection.name, pic: connection.pic)
            connection.update_attributes!(account_id: account.id)
            omei = Core::Star.find_by id: 423
            user.follow(omei) if omei
            # TaskWorker.perform_async(account.id, 'user')
          end
        end
      end
      if succeed
        account = connection.account
        user = account.user
        account.v3_count.increment(1)
        CoreLogger.info(logger_format(api: "conection_callback", account_id: @current_account.try(:id), connection: connection.try(:id)))
        success(data: {
          v3_count: account.tries(:v3_count, :value),
          user: {
            uid: account.id,
            token: account.login_salt || account.reset_login_salt,
            name: user.name,
            pic: user.app_picture_url,
            birthday: user.birthday,
            connection_id: connection.id,
            role: user.identity
          }
        })
      else
        fail(0, "绑定失败")
      end
    end

    params do
      requires :conection_id, type: String
    end
    delete :conection_unbinding do
      return fail(0, "已用该账户登录，不容许解绑") if @current_account.connections.count < 2 && @current_account.crypted_password.blank?
      connection = Core::Connection.active.find_by(id: params[:conection_id])
      return fail(0, "解除绑定失败")  if @current_user.nil? || @current_user.id != connection.try(:account_id)
      # connection.update_attributes(account_id: nil, active: false)
      @current_account.connections.active.where(site: connection.site).each do |c|
        c.update(active: false)
      end
      # connection.update_attributes(active: false)
      CoreLogger.info(logger_format(api: "conection_unbinding", account_id: @current_account.try(:id), connection: connection.try(:id)))
      success(data: true)
    end
  end
end
