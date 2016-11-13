module V4
  class ConnectionApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      requires :site, type: String
      requires :identifier, type: String
      optional :old_identifier, type: String
      requires :token, type: String
      optional :name, type: String
      optional :pic, type: String
      optional :expired_at, type: DateTime
      optional :data, type: Hash
    end
    post :conection_callback do
      return fail(0, "参数错误") unless %w(qq wechat weibo).include?(params[:site].to_s)
      #有两个账号 ios 和 android 都存在一个不同的账户 android 微信bug
      @old_connection = Core::Connection.active.find_by(site: params[:site], identifier: params[:old_identifier])
      @connection = Core::Connection.active.find_by(site: params[:site], identifier: params[:identifier])
      if params[:site] == "wechat"
        if @old_connection.present? && @connection.present?
          database_transaction do
            @connection.old_identifier = @old_connection.identifier
            Shop::OrderItem.where(user_id: @old_connection.account_id).each do |o|
              o.update!(user_id: @connection.account_id)
            end
            Shop::Order.where(user_id: @old_connection.account_id).each do |o|
              o.update!(user_id: @connection.account_id)
            end
            Shop::FundingOrder.where(user_id: @old_connection.account_id).each do |o|
              o.update!(user_id: @connection.account_id)
            end
            Core::Account.find_by(id: @old_connection.account_id).update!(active: false)
            Core::User.find_by(id: @old_connection.account_id).update!(active: false)
            Core::Punch.where(user_id: @old_connection.account_id).each do |p|
              p.update(user_id: @connection.account_id)
            end
            Core::Expen.where(user_id: @old_connection.account_id).each do |c|
              c.update(user_id: @connection.account_id)
            end
            @old_connection.update!(active: false)
          end
        elsif @old_connection.present? && !@connection.present?
          @connection = @old_connection
          @connection.identifier = params[:identifier]
          @connection.old_identifier = params[:old_identifier]
        end
      end
      @connection = Core::Connection.active.find_or_initialize_by(site: params[:site], identifier: params[:identifier]) unless @connection.present?
      name = params[:name].to_s.strip_emoji
      @connection.attributes = {
        token: params[:token],
        name: name,
        pic: params[:pic],
        expired_at: params[:site] == 'weibo' ? (Time.now + 29.days) : params[:expired_at],
        data: params[:data].to_s.strip_emoji
      }
      begin
        database_transaction do
          if @connection.save!
            #之前已成为owhat用户的第三方账户登陆
            @account = @connection.account
            if @account.present? && (@account.phone.present? || @account.email.present?)
              @user = @account.user
              @account.v3_count.increment(1)
              CoreLogger.info(logger_format(api: "conection_callback",  type: "account is exist", connection_id: @connection.try(:id)))
              return success(data: {
                v3_count: @account.tries(:v3_count, :value),
                user: {
                  uid: @account.id,
                  token: @account.login_salt,
                  name: @user.name,
                  pic: @user.app_picture_url,
                  birthday: @user.birthday,
                  connection_id: @connection.id,
                  role: @user.identity
                }
              })
            else
              CoreLogger.info(logger_format(api: "conection_callback", type: "account is nil", connection_id: @connection.try(:id)))
              return success(data: { code: "联合登陆", connection_id: @connection.id })
            end
          else
            return fail(0, "登录失败，第三方网络请求失败！")
          end
        end
      rescue Exception => e
        SendEmailWorker.perform_async(6, "登陆错误#{e}, #{params[:site]} #{params[:identifier]}", "core_connection")
        return fail(0, "登陆异常错误，请联系客服，客服电话4008980812")
      end
    end

    desc "关联账号"
    params do
      requires :connection_id, type: Integer
      requires :password, type: String
      requires :login, type: String, desc: "手机号或者邮箱"
    end
    post :connection_account do
      connect = Core::Connection.active.find_by(id: params[:connection_id])
      return fail(0, "第三方账户不存在！") unless connect.present?
      params[:login].to_s.is_mobile? ? phone = params[:login] : email = params[:login]
      if phone.present?
        account = Core::Account.active.find_by(phone: phone)
      else
        account = Core::Account.active.find_by(email: email)
      end
      return fail(0, "您要关联的主账号不存在！") unless account.present?
      return fail(0, "密码错误！") unless account.authenticated?(params[:password])
      return fail(0, "认证用户只能选择一键注册新的账号，保证您的账户安全以及您还是认证账户的身份") if connect.account_id.present? && connect.account.user.verified?
      user = account.user
      return fail(0, "您要关联的账号存在异常，请联系客服！") unless user.present?
      if account.connections.active.present?
        #已有第三方关联
        ## 判断是不是site一致的关联 如果一直关联 跳到关联页面 不是一致的自动关联并登陆
        ### 最多 微博一个 qq两个重复的 微信两个重复的
        return fail(0, "不能重复绑定多个微博账号") if connect.site == 'weibo' && account.connections.active.where(site: connect.site).size >= 1
        account_connection = account.connections.active.where(site: connect.site).first
        if account_connection.present?
          connections =[{name: account_connection.name, pic: account_connection.picture_url}, {name: connect.name, pic: connect.picture_url}]
          return success(data: {
            main_connection: {
              name: account.user.name,
              pic: account.user.picture_url
            },
            account_id: account.id,
            connections: connections
          })
        else
          if connect.account_id.present?
            #绑在account有phone的上面
            database_transaction do
              Shop::OrderItem.where(user_id: connect.account_id).each do |o|
                o.update(user_id: account.id)
              end
              Shop::Order.where(user_id: connect.account_id).each do |o|
                o.update(user_id: account.id)
              end
              Shop::FundingOrder.where(user_id: connect.account_id).each do |f|
                f.update(user_id: account.id)
              end
              Core::Punch.where(user_id: connect.account_id).each do |p|
                p.update(user_id: account.id)
              end
              Core::Expen.where(user_id: connect.account_id).each do |p|
                p.update(user_id: account.id)
              end
              user.update(old_uid: connect.account.user.old_uid) if connect.account && connect.account.user.present? &&  connect.account.user.old_uid.present? #此处更新old_uid
            end
          end
          connect.account_id = account.id
          connect.save
          account.v3_count.increment(1)
          CoreLogger.info(logger_format(api: "connection_account", connection_id: connect.try(:id), account_id: account.try(:id)))
          success(data: {
            v3_count: account.tries(:v3_count, :value),
            user: {
              uid: account.id,
              token: account.login_salt || account.reset_login_salt,
              name: user.name,
              pic: user.app_picture_url,
              birthday: user.birthday,
              connection_id: connect.id,
              role: user.identity
            }
          })
        end
      else
        #没有第三方关联
        ##判断是不是之前已经有account_id， 或者是新的版本进的没有account_id
        if connect.account_id.present?
          #绑在account有phone的上面
          database_transaction do
            Shop::OrderItem.where(user_id: connect.account_id).each do |o|
              o.update(user_id: account.id)
            end
            Shop::Order.where(user_id: connect.account_id).each do |o|
              o.update(user_id: account.id)
            end
            Shop::FundingOrder.where(user_id: connect.account_id).each do |f|
              f.update(user_id: account.id)
            end
            Core::Punch.where(user_id: connect.account_id).each do |a|
              a.update(user_id: account.id)
            end
            Core::Expen.where(user_id: connect.account_id).each do |e|
              e.update(user_id: account.id)
            end
            user.update(old_uid: connect.account.user.old_uid) if connect.account && connect.account.user.present? &&  connect.account.user.old_uid.present? #此处更新old_uid
          end
        end
        connect.account_id = account.id
        connect.save
        user = account.user
        account.v3_count.increment(1)
        CoreLogger.info(logger_format(api: "connection_account", connection_id: connect.try(:id), account_id: account.try(:id)))
        success(data: {
          v3_count: account.tries(:v3_count, :value),
          user: {
            uid: account.id,
            token: account.login_salt || account.reset_login_salt,
            name: user.name,
            pic: user.app_picture_url,
            birthday: user.birthday,
            connection_id: connect.id,
            role: user.identity
          }
        })
      end
    end

    desc "快速注册"
    params do
      optional :email, type: String
      optional :phone, type: String
      requires :captcha, type: String
      requires :password, type: String
      optional :client, type: String
      optional :connection_id, type: Integer
    end
    post :register do
      connect = Core::Connection.active.find_by(id: params[:connection_id])
      return fail(0, "第三方账号不存在！") unless connect.present?
      return fail(0, "第三方账号已经绑定过主账号") if connect.account_id.present? && (connect.account.phone.present? || connect.account.email.present?)
      return fail(3) unless params[:phone].to_s.is_mobile? || params[:email].to_s.is_email?
      @account = Core::Account.new(params.slice(:email, :phone, :password, :client).to_h)
      @account.client = params[:from_client]
      return fail(4) unless @account.make_phone_verify_code(params[:captcha])
      succeed = database_transaction do
        if connect.account_id.present?
          connect.account.update_attributes!(params.slice(:email, :phone, :password, :client).to_h)
        else
          @account.save!
          @user = Core::User.new
          @user.id = @account.id
          @user.name = "O星人#{SecureRandom.urlsafe_base64(6)}"
          @user.save!
          @account.v3_count.increment(1)
          connect.account_id = @account.id
          connect.save!
        end
      end
      @account = connect.account

      if succeed
        @account.v3_count.increment(1)
        @user = @account.user
        omei = Core::Star.active.published.find_by id: 423
        @user.follow_and_update_cache(omei) if omei
        # TaskWorker.perform_async(@user.id, 'user')
        CoreLogger.info(logger_format(api: "register", account_id: @account.try(:id)))
        success(data: {
          v3_count: @account.v3_count.value,
          user: {
            uid: @account.id,
            token: @account.login_salt || @account.reset_login_salt,
            pic: @user.picture_url,
            name: @user.name,
            birthday: @user.birthday,
            role: @user.identity
          }
        })
      else
        fail(0, "注册失败")
      end
    end

    desc "确认关联owhat账号"
    params do
      optional :account_id, type: Integer
      optional :connection_id, type: Integer
    end
    post :bang_connections do
      connect = Core::Connection.active.find_by(id: params[:connection_id])
      fail(0, '找不到该第三方用户') unless connect.present?
      return fail(0, "第三方账号已经绑定过主账号") if connect.account_id.present? && (connect.account.phone.present? || connect.account.email.present?)
      account = Core::Account.active.find_by(id: params[:account_id])
      fail(0, '找不到该关联主账号') unless account.present?

      user = account.user
      if connect.account_id.present?
        #绑在account有phone的上面
        database_transaction do
          Shop::OrderItem.where(user_id: connect.account_id).each do |o|
            o.update(user_id: account.id)
          end
          Shop::Order.where(user_id: connect.account_id).each do |o|
            o.update(user_id: account.id)
          end
          Shop::FundingOrder.where(user_id: connect.account_id).each do |o|
            o.update(user_id: account.id)
          end
          Core::Punch.where(user_id: connect.account_id).each do |o|
            o.update(user_id: account.id)
          end
          Core::Expen.where(user_id: connect.account_id).each do |o|
            o.update(user_id: account.id)
          end
        end
      end
      connect.account_id = account.id

      if connect.save
        CoreLogger.info(logger_format(api: "register", connect_id: connect.try(:id), account_id: account.try(:id)))
        success(data: {
          v3_count: account.v3_count.value,
          user: {
            uid: account.id,
            token: account.login_salt || account.reset_login_salt,
            pic: user.picture_url,
            name: user.name,
            birthday: user.birthday,
            role: user.identity
          }
        })
      else
        fail(0, "绑定失败")
      end
    end


    params do
      requires :uid, type: String
      requires :site, type: String
      requires :identifier, type: String
      requires :token, type: String
      optional :name, type: String
      optional :pic, type: String
      optional :expired_at, type: DateTime
      optional :data, type: Hash
    end
    post :share_connection_callback do
      return fail(0, "该用户不存在") unless @current_user.present?
      return fail(0, "参数错误") unless %w(qq wechat weibo).include?(params[:site].to_s)
      connection = Core::Connection.active.find_or_initialize_by(site: params[:site], identifier: params[:identifier])
      connection.attributes = {
        token: params[:token],
        name: params[:name].to_s.strip_emoji,
        pic: params[:pic],
        expired_at: params[:site] == 'weibo' ? (Time.now + 29.days) : params[:expired_at],
        data: params[:data].to_s.strip_emoji
      }
      if connection.id.present? && connection.account_id.present?
        return fail(0, "该账号已绑定") if connection.account_id != @current_user.id
        return fail(0, "更新失败") unless connection.save
      else
        share_info = @current_user.weibo_auto_share_info
        return fail(0, "该账号已绑定") if share_info[:has_weibo] == true
        connection.account_id = @current_user.id
        return fail(0, "绑定失败") unless connection.save
      end
      CoreLogger.info(logger_format(api: "share_connection_callback", data: params.to_json))
      success(data: true)
    end

  end
end
