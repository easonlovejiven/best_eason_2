# encoding:utf-8

module V3
  class UsersApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      optional :login, type: String
      optional :email, type: String
      optional :phone, type: String
      requires :password, type: String
    end
    post :login do
      @account = Core::Account.search_by_params(params.slice(:login, :email, :phone).to_h)

      return fail(0, "该用户未注册") unless @account
      if @account && @account.authenticated?(params[:password])
        @account.v3_count.increment(1)
        success(data: {
          v3_count: @account.v3_count.value,
          user: {
            uid: @account.id,
            token: @account.login_salt || @account.reset_login_salt,
            name: @account.user.name,
            pic: @account.user.picture_url,
            birthday: @account.user.birthday,
            role: @account.user.identity
          }
        })
        #判断用户是否在当日登陆过
        CoreLogger.info(logger_format(api: "login", email: params[:email], phone: params[:phone] ))
        unless Redis.current.get("core_user_login_by_#{@account.user.id}_at_#{Time.now.beginning_of_day}")
          Redis.current.set("core_user_login_by_#{@account.user.id}_at_#{Time.now.beginning_of_day}", 1)
          AwardWorker.perform_async(@account.user.id, @account.user.id, @account.user.class.name, 1, 0, 'self', :award )
        end
      else
        fail(0, "登录失败")
      end
    end

    params do
      optional :email, type: String
      optional :phone, type: String
      requires :captcha, type: String
      requires :password, type: String
      optional :client, type: String
    end
    post :register do
      return fail(3) unless params[:phone].to_s.is_mobile? || params[:email].to_s.is_email?
      @account = Core::Account.new(params.slice(:email, :phone, :password, :client).to_h)
      return fail(4) unless @account.make_phone_verify_code(params[:captcha])
      success = database_transaction do
        @account.client = params[:from_client]
        @account.save!
        @user = Core::User.new
        @user.id = @account.id
        @user.name = "O星人#{SecureRandom.urlsafe_base64(6)}"
        @user.save!
        @account.v3_count.increment(1)
      end

      if success
        omei = Core::Star.find_by id: 423
        @user.follow_and_update_cache(omei) if omei
        # TaskWorker.perform_async(@user.id, 'user')
        CoreLogger.info(logger_format(api: "register", email: params[:email], phone: params[:phone], client: params[:client]))
        success(data: {
          v3_count: @account.v3_count.value,
          user: {
            uid: @account.id,
            token: @account.login_salt || @account.reset_login_salt,
            pic: @user.picture_url,
            name: @user.name,
            birthday: @user.birthday,
            role: @user.role
          }
        })
      else
        fail(0)
      end
    end

    params do
      requires :phone, type: String
      optional :type, type: String
    end
    post :registration_code do
      res = Core::MobileCode.send_code(params[:phone], 'app', params[:type], 10)
      if res
        if res[:ret]
          success(data: true)
        elsif res[:error] == 'Send SMS messages beyond the limit of five per day.'
          fail(0, "每天每个手机号限制发送5条，您已经超出5条！")
        else
          fail(0, res[:error])
        end
      else
        fail(0, "网络超时")
      end
    end

    params do
      requires :phone, type: String
      optional :genre, type: String
    end
    get :validate_account do
      return fail(1) unless params[:phone].to_s.is_mobile?
      if params[:genre] == "reset"
        return fail(0, "手机号未注册") unless Core::Account.active.find_by(phone: params[:phone])
      else
        return fail(6) if Core::Account.active.find_by(phone: params[:phone])
      end
      success(data: true)
    end

    params do
      optional :uid
      requires :phone, type: String
      optional :password, type: String
    end
    put :update_password do
      phone = params[:phone].to_s
      password = params[:password].to_s
      return fail(1) unless phone.is_mobile?
      if @current_account
        # 第三方登录绑定手机号
        account_params = if @current_account.crypted_password.blank?
          account = Core::Account.active.find_by phone: phone
          return fail(0, "该手机号已绑定") if account.present?
          { phone: phone, password: password }
        # 邮箱注册账户绑定手机号
      elsif @current_account.email.present? && @current_account.phone.blank? # && @current_account.crypted_password
          account = Core::Account.active.find_by phone: phone
          return fail(0, "该手机号已绑定") if account.present?
          if password.present?
            { phone: phone, password: password }
          else
            { phone: phone }
          end
        else
          {phone: phone, password: password }
        end
        if @current_account.update_attributes(account_params)
          CoreLogger.info(logger_format(api: "update_password"))
          success(data: true)
        else
          fail(0, "修改失败")
        end
      else
        account = Core::Account.active.find_or_initialize_by(phone: phone)
        # return fail(6) unless account
        account.password = params[:password]
        if account.save(validate: false)
          CoreLogger.info(logger_format(api: "update_password"))
          success(data: true)
        else
          fail(0, "修改失败")
        end
      end
    end

    params do
      requires :birthday, type: String
      requires :name, type: String
      requires :pic, type: String
    end
    put :update_user_info do
      info = {}
      info[:birthday] = params[:birthday] if params[:birthday].present?
      info[:name] = params[:name] if params[:name].present?
      info[:pic] = params[:pic] if params[:pic].present?
      return fail(0, "参数错误") if info.blank?
      return fail(0, "认证的用户需要联系O妹才能修改昵称哟 ~") if @current_user.verified? && (info[:name] != @current_user.name)
      @current_user.name = info[:name] unless info[:name].nil?
      name_result = @current_user.validate_user_name
      return fail(0, name_result[:msg]) if name_result[:status] == false
      if @current_user.update_attributes(info)
        CoreLogger.info(logger_format(api: "update_user_info", info: info.to_json))
        success(data: true)
      else
        fail(0, "修改失败")
      end
    end

    params do
      requires :birthday, type: String
    end
    put :user_birthday do
      if @current_user.update_attributes(birthday: params[:birthday])
        CoreLogger.info(logger_format(api: "user_birthday", birthday: params[:birthday]))
        success(data: true)
      else
        fail(0, "修改失败")
      end
    end

    params do
      requires :name, type: String
    end
    put :user_name do
      return fail(0, "认证的用户需要联系O妹才能修改昵称哟 ~") if @current_user.verified? && (params[:name] != @current_user.name)
      @current_user.name = params[:name] unless params[:name].nil?
      name_result = @current_user.validate_user_name
      return fail(0, name_result[:msg]) if name_result[:status] == false
      if @current_user.update_attributes(name: params[:name])
        CoreLogger.info(logger_format(api: "user_name", name: params[:name]))
        success(data: true)
      else
        fail(0, "修改失败")
      end
    end

    params do
      requires :sex, type: String
    end
    put :user_sex do
      return fail(0, "参数错误") unless %w(male female).include?(params[:sex])
      if @current_user.update_attributes(sex: params[:sex])
        CoreLogger.info(logger_format(api: "user_sex", sex: params[:sex]))
        success(data: true)
      else
        fail(0, "修改失败")
      end
    end

    params do
      requires :signature, type: String
    end
    put :user_signature do
      if @current_user.update_attributes(signature: params[:signature])
        CoreLogger.info(logger_format(api: "user_signature", signature: params[:signature]))
        success(data: true)
      else
        fail(0, "修改失败,或许您可以试着不要添加表情符号哦。")
      end
    end

    params do
      requires :pic, type: String
    end
    put :user_avatar do
      if @current_user.update_attributes(pic: params[:pic])
        CoreLogger.info(logger_format(api: "user_avatar", pic: params[:pic]))
        success(data: { user: {id: @current_user.id, pic: @current_user.picture_url }})
      else
        fail(0, "修改失败")
      end
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :user_images do
      images = Core::Image.published.select("id, pic").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      success(data: { count: images.total_entries, images: images.as_json } )
    end

    params do
      requires :image_id, type: Integer
    end
    put :user_cover do
      if @current_user.update_attributes(image_id: params[:image_id])
        CoreLogger.info(logger_format(api: "user_cover", image_id: params[:image_id]))
        success(data: true)
      else
        fail(0, "修改失败")
      end
    end

    params do
      requires :privacy, type: Boolean
    end
    put :user_privacy do
      if @current_user.update_attributes(privacy: params[:privacy])
        CoreLogger.info(logger_format(api: "user_privacy", privacy: params[:privacy]))
        success(data: true)
      else
        fail(0, "修改失败")
      end
    end

    params do
      requires :phone, type: String
      requires :captcha, type: String
      optional :uid, type: Integer
    end
    get :verify_code do
      return fail(1) unless params[:phone].to_s.is_mobile?
      if @current_account && @current_account.phone.blank?
        @current_account.bunding_verify_code(params[:phone], params[:captcha]) ? success({data: true}) : fail(4)
      else
        account = Core::Account.active.find_by(phone: params[:phone])
        return fail(6) unless account
        account.make_phone_verify_code(params[:captcha]) ? success({data: true}) : fail(4)
      end
    end

    params do
      requires :site, type: String
    end
    post :callback do
      site = params[:site].to_s
      config = OAUTH_CONFIG[site]
      case site
      when 'qq'
        options = { :grant_type => 'authorization_code', :client_id => config['key'], :client_secret => config['secret'], :code => params[:code], :redirect_uri => params[:state] }
        token_url = "#{config['site']}#{config['request_token_path']}?#{options.map{|k,v| "#{k}=#{CGI::escape(v)}"}.join('&')}"
        resp_token = HTTParty.get(token_url).body.split("&").map{|str| str.split("=") }.map{|k,v| {k => v}}.inject(&:merge)
        resp_openid = JSON.parse(HTTParty.get("#{config['site']}#{config['access_token_path']}?access_token=#{resp_token['access_token']}").body.match(/\{.*\}/).to_s)
        @connection = Core::Connection.active.find_or_initialize_by(site: 'qq', identifier: resp_openid['openid'])
        @connection.token = resp_token['access_token']
        resp_user_info = JSON.parse(HTTParty.get("https://graph.qq.com/user/get_user_info?access_token=#{resp_token['access_token']}&oauth_consumer_key=#{config['key']}&openid=#{resp_openid['openid']}").body)
        @connection.data = resp_user_info.to_json
        @connection.name = resp_user_info['nickname']
        @connection.sex = (resp_user_info['gender'] == '男') ? 'male' : 'female'
        @connection.save
        CoreLogger.info(logger_format(api: "callback", connection_id: @connection.try(:id)))
      end
    end

    params do
      requires :follow_id, type: Integer
    end
    put :user_follow do
      follow = Core::User.find(params[:follow_id])
      if !@current_user.following?(follow) && @current_user.follow_and_update_cache(follow)
        CoreLogger.info(logger_format(api: "user_follow", follow_id: params[:follow_id]))
        success(data: { id: follow.id, friendship: @current_user.friendship[follow.follow_key].to_i })
      else
        fail(0, "关注失败")
      end
    end

    params do
      requires :follow_id, type: Integer
    end
    put :user_unfollow do
      follow = Core::User.find(params[:follow_id])
      return fail(0, "不能关注自己") if follow.id == @current_user.id
      @current_user.unfollow_and_update_cache(follow)
      CoreLogger.info(logger_format(api: "user_unfollow", follow_id: params[:follow_id]))
      success(data: { id: follow.id, friendship: @current_user.friendship[follow.follow_key].to_i })
    end

    params do
      optional :user_id, type: Integer
      optional :identity, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :user_followers do
      return fail(0, "参数错误") unless [0, 1, 2].include?(params[:identity].to_i) || params[:identity].blank?
      user = params[:user_id].blank? ? @current_user : Core::User.find(params[:user_id])
      scope = user.followers_scoped
      scope = scope.where(followable_type: 'Core::User').joins(:user).where("`core_users`.`identity` = #{params[:identity]}") if params[:identity]
      followers = scope.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      count = followers.total_entries
      followers = followers.map(&:follower).map do |f|
        {
          id: f.id,
          name: f.name,
          role: f.identity,
          pic: f.app_picture_url,
          friendship: user.friendship[f.follow_key].to_i,
          follow_count: f.follow_count,
          followers_count: f.followers_count
        }
      end
      res = { data: { follows: followers, count: count } }
      success(res)
    end

    params do
      requires :user_id, type: Integer
      optional :identity, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :user_followings do
      return fail(0, "参数错误") unless [0, 1, 2].include?(params[:identity].to_i) || params[:identity].blank?
      user = params[:user_id].blank? ? @current_user : Core::User.find(params[:user_id])

      scope = user.follows_scoped
      scope = scope.where(followable_type: 'Core::User').joins(:followable_user).where("`core_users`.`identity` = #{params[:identity]}") if params[:identity].present?
      follows = scope.order(updated_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      count = follows.total_entries
      follows = follows.map(&:followable).map do |f|
        {
          id: f.id,
          name: f.name,
          role: f.respond_to?(:identity) ? f.identity : 'star',
          pic: f.app_picture_url,
          friendship: (f.respond_to?(:identity) ? user.friendship[f.follow_key].to_i : (user.following?(f) ? 1 : 0)),
          follow_count: (f.respond_to?(:identity) ? f.follow_count : 0),
          followers_count: (f.respond_to?(:identity) ? f.followers_count : f.fans_total)
        }
      end
      res = {data: { follows: follows, count: count } }
      success(res)
    end

    get :user_info do
      return fail(0, "用户不存在!") unless @current_user.present?
      share_info = @current_user.weibo_auto_share_info
      info = {
        id: @current_user.id,
        name: @current_user.name,
        pic: @current_user.picture_url,
        cover_id: @current_user.image_id,
        city: @current_user.tries(:address, :city),
        address: @current_user.tries(:address, :address),
        address_id: @current_user.tries(:address, :id),
        sex: @current_user.sex,
        birthday: @current_user.birthday,
        signature: @current_user.signature,
        auto_share_status: share_info[:auto_share_status],
        has_weibo: share_info[:has_weibo],
        weibo_token_active: share_info[:weibo_token_active]
      }
      success(data: { user: info } )
    end

    desc "上传语音接口"
    params do
      requires :uid, type: Integer
      requires :voice_key, type: String
      requires :pic_key, type: String
      requires :duration, type: String
      requires :title, type: String
      requires :star_list, type: String
    end
    post :upload_voice do
      key = Base64.encode64("#{Rails.application.secrets.qiniu_host_name}:#{params[:voice_key]}_server").gsub!("\n", '')
      put_policy = Qiniu::Fop::Persistance::PfopPolicy.new("#{Rails.application.secrets.qiniu_host_name}", params[:voice_key], "avthumb/mp3|saveas/#{key}", 'http://#{request.host_with_port}/v3/qiniu_notify')
      code,result,esponse_headers = Qiniu::Fop::Persistance.pfop(put_policy)
      if result['persistentId']
        params_hash = {key: "#{params[:voice_key]}_server", user_id: params[:uid], pic_key: params[:pic_key], duration: params[:duration], star_list: params[:star_list], title: params[:title]}
        voice = Welfare::Voice.new(params_hash)
        if voice.save
          CoreLogger.info(logger_format(api: "upload_voice", voice_id: voice.try(:id)))
          success({data: true})
        else
          fail(0, '创建语音失败')
        end
      else
        fail(0, '语音转换失败，请重新发布任务')
      end
    end

    desc "查看语音接口"
    params do
      requires :uid, type: Integer
      requires :welfare_voice_id, type: Integer
    end
    get :get_welfare_voice do
      voice = Welfare::Voice.find_by(id: params[:welfare_voice_id])
      user_id = voice.user_id
      if voice && voice.active
        if @current_user.id != user_id
          @complete = voice.shop_task.task_state["#{voice.class.to_s}:#{@current_user.id}"].to_i > 0
          return fail(0, 'O!元不够') unless @complete || @current_user.obi >= 5
          voice.shop_task.payment_obi(@current_user, status: :complete) unless @complete
        end
        voice = voice.as_json.merge!({key_url: Settings.qiniu["host"]+'/'+voice['key'], pic_url: Settings.qiniu["host"]+'/'+voice['pic_key'], complete: @complete })
        success({data: voice})
      else
        fail(0, '语音查找失败')
      end

    end

    desc "用户里程碑"
    params do
      requires :uid, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :user_timeline do
      user = Core::User.find_by(id: params[:uid])
      per_page = params[:per_page].present? ? params[:per_page] : 10
      return fail(0, "用户不存在") unless user
      feeds, count = Rails.cache.fetch("user_timeline_by_#{user.id}_page:#{params[:page]}_per_page:#{per_page}", expires_in: 10.minutes) do
        if user.verified?
          feeds = Shop::Task.published.where(user_id: user.id)
          feeds = feeds.where.not(shop_type: ['Welfare::Product', 'Welfare::Event']) unless version_compare
          feeds = feeds.joins("LEFT JOIN core_users AS users ON users.id = shop_tasks.user_id").order(created_at: :desc)
            .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
          count = feeds.total_entries
          feeds = feeds.map{ |f| h = f.as_json.merge!({
            is_free: f.free,
            owhat_product_id: f.shop.id,
            user_id: f.user.id,
            title: f.title,
            pic: f.shop.cover_pic,
            participator: f.participants,
            owhat_product_type: f.shop_type,
            is_completed: f.task_state["#{f.shop_type}:#{user.id}"].to_i > 0 }).update({created_at: f.created_at.to_s(:db)}) and f.shop_type.match(/Welfare/) ? h.merge!({obi: '打开福利消耗O元', empirical_value: '发布福利得经验值'}) : h.merge!({obi: '做任务得O!元为花费金额的10%', empirical_value: '分享再得1 O元'})
            case f.shop_type
            when 'Shop::Subject'
              h.update(participator: Redis.current.get("subject:#{f.shop_id}:read_subject_participator").to_i)
            when 'Shop::Media'
              h.update(participator: Redis.current.get("media:#{f.shop_id}:read_subject_participator").to_i)
            end
            h
          }
        else
          sql1 = "SELECT `o`.owhat_product_id, `o`.user_id AS user_id, `o`.owhat_product_type, `o`.created_at FROM `shop_order_items` AS `o` WHERE `o`.user_id = #{user.id} AND `o`.status = 2"
          sql2 = "SELECT `f`.shop_funding_id, `f`.user_id AS user_id, `f`.shop_funding_type, `f`.created_at FROM `shop_funding_orders` AS `f`  WHERE `f`.user_id = #{user.id} AND `f`.status = 2"
          sql3 = "SELECT `w`.resource_id, `w`.user_id AS user_id, `w`.resource_type, `w`.created_at FROM `core_expens` AS `w` WHERE `w`.user_id = #{user.id}"
          feeds = Shop::OrderItem.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) UNION ALL (#{sql3}) ORDER BY created_at DESC LIMIT #{per_page} OFFSET #{(params[:page] - 1)*per_page || 0};")
          count = Shop::OrderItem.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) UNION ALL (#{sql3})").count
          feeds= feeds.map{ |f| h = f.as_json.merge!({
            is_free: f.owhat_product.shop_task.free,
            title: f.owhat_product.title,
            pic: f.owhat_product.cover_pic,
            participator: f.owhat_product.shop_task.participants,
            is_completed: f.owhat_product.shop_task.task_state["#{f.owhat_product.class.to_s}:#{user.id}"].to_i > 0 }).update({created_at: f.created_at.to_s(:db)}) and f.owhat_product_type.match(/Welfare/) ? h.merge({obi: '打开福利消耗O元', empirical_value: '发布福利得经验值'}) : h.merge!({ obi: '做任务得O!元为花费金额的10%', empirical_value: '做任务得经验值同花费金额' })
            case f.owhat_product.class.to_s
            when 'Shop::Subject'
              h.update(participator: Redis.current.get("subject:#{f.owhat_product.id}:read_subject_participator").to_i)
            when 'Shop::Media'
              h.update(participator: Redis.current.get("media:#{f.owhat_product.id}:read_subject_participator").to_i)
            end
            h
          }
        end
        [feeds, count]
      end
      success(data: {
        feeds: feeds,
        count: count,
        share_url: "#{Rails.application.routes.default_url_options[:host]}/home/users/#{params[:uid]}?category=milestone",
        has_next: feeds.size == per_page ,
        user: {
          id: user.id,
          name: user.name,
          level: user.level,
          pic: user.picture_url,
          image: user.image.try(:picture_url) || Core::Image.published.first.tries(:picture_url),
          identity: user.identity,
          verified: user.verified,
          balance_account: user.balance_account, #账户余额
          welfare_count: user.task_count('welfare'), #发布福利总数
          shop_count: user.task_count('task'), #发布任务总数
          participator: user.shop_tasks.map{|task| task.participator}.sum,
        },
        sign: Redis.current.get("User:Milestone:#{user.id}") ? eval(Redis.current.get("User:Milestone:#{user.id}")) : nil
      })
    end

    desc "个人主页"
    params do
      requires :uid, type: Integer #我的id
      requires :user_id, type: Integer #要访问的人的id
      optional :page, type: Integer
      optional :per_page, type: Integer
    end

    get :get_personal_homepage do
      user = Core::User.find_by(id: params[:uid])
      other_user = Core::User.find_by(id: params[:user_id])
      return fail(0, "用户不存在") unless other_user
      per_page = params[:per_page].present? ? params[:per_page] : 10
      return fail(0, "用户不存在") unless user
      if other_user.privacy || other_user.verified?
        feeds, count = Rails.cache.fetch("personal_homepage_by_#{other_user.id}_page:#{params[:page]}_per_page:#{per_page}", expires_in: 10.minutes) do
          if other_user.verified?
            feeds = Shop::Task.published.where(user_id: other_user.id)
            feeds = feeds.where.not(shop_type: ['Welfare::Product', 'Welfare::Event']) unless version_compare
            feeds = feeds.joins("LEFT JOIN core_users AS users ON users.id = shop_tasks.user_id").order(created_at: :desc)
              .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
            count = feeds.total_entries
            feeds = feeds.map{ |f| h = f.as_json.merge!({
              is_free: f.free,
              owhat_product_id: f.shop.id,
              user_id: f.user.id,
              title: f.title,
              pic: f.shop.cover_pic,
              participator: f.participants,
              owhat_product_type: f.shop_type,
              is_completed: f.task_state["#{f.shop_type}:#{user.id}"].to_i > 0 }).update({created_at: f.created_at.to_s(:db)})
              case f.shop_type
              when 'Shop::Subject'
                h.update(participator: Redis.current.get("subject:#{f.shop_id}:read_subject_participator").to_i)
              when 'Shop::Media'
                h.update(participator: Redis.current.get("media:#{f.shop_id}:read_subject_participator").to_i)
              end
              h
            }
            if user.verified?
              feeds = feeds.map{ |f| f[:owhat_product_type].match(/Welfare/) ? f.as_json.merge!({obi: '打开福利消耗O元', empirical_value: '发布福利得经验值', spend_obi: "5"}) : f.as_json.merge!({obi: '做任务得O!元为花费金额的1%', empirical_value: '分享再得1 O元', spend_obi: "0.1"}) }
            else
              feeds = feeds.map{ |f| f[:owhat_product_type].match(/Welfare/) ? f.as_json.merge!({obi: '打开福利消耗O元', empirical_value: '发布福利得经验值', spend_obi: "5"}) : f.as_json.merge!({obi: '做任务得O!元为花费金额的1%', empirical_value: '做任务得经验值同花费金额', spend_obi: "0.1"}) }
            end
          else
            sql1 = "SELECT `o`.owhat_product_id, `o`.user_id AS user_id, `o`.owhat_product_type, `o`.created_at FROM `shop_order_items` AS `o` WHERE `o`.user_id = #{other_user.id} AND `o`.status = 2"
            sql2 = "SELECT `f`.shop_funding_id, `f`.user_id AS user_id, `f`.shop_funding_type, `f`.created_at FROM `shop_funding_orders` AS `f`  WHERE `f`.user_id = #{other_user.id} AND `f`.status = 2"
            sql3 = "SELECT `w`.resource_id, `w`.user_id AS user_id, `w`.resource_type, `w`.created_at FROM `core_expens` AS `w` WHERE `w`.user_id = #{other_user.id}"
            feeds = Shop::OrderItem.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) UNION ALL (#{sql3}) ORDER BY created_at DESC LIMIT #{per_page} OFFSET #{(params[:page] - 1)*per_page || 0};")
            count = Shop::OrderItem.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) UNION ALL (#{sql3})").count
            if user.verified?
              feeds= feeds.map{ |f| h = f.as_json.merge!({
                is_free: f.owhat_product.shop_task.free,
                title: f.owhat_product.title,
                pic: f.owhat_product.cover_pic,
                participator: f.owhat_product.shop_task.participants,
                is_completed: f.owhat_product.shop_task.task_state["#{f.owhat_product.class.to_s}:#{@current_user.id}"].to_i > 0, spend_obi: "5" }).update({created_at: f.created_at.to_s(:db)}) and f.owhat_product_type.match(/Welfare/) ? h.merge({obi: '发布福利得O元', empirical_value: '发布福利得经验值'}) : h.merge!({ obi: '做任务得O!元为花费金额的1%', empirical_value: '分享再得1 O元' })
                case f.owhat_product.class.to_s
                when 'Shop::Subject'
                  h.update(participator: Redis.current.get("subject:#{f.owhat_product.id}:read_subject_participator").to_i)
                when 'Shop::Media'
                  h.update(participator: Redis.current.get("media:#{f.owhat_product.id}:read_subject_participator").to_i)
                end
                h
              }
            else
              feeds= feeds.map{ |f| h = f.as_json.merge!({
                is_free: f.owhat_product.shop_task.free,
                title: f.owhat_product.title,
                pic: f.owhat_product.cover_pic,
                participator: f.owhat_product.shop_task.participants,
                is_completed: f.owhat_product.shop_task.task_state["#{f.owhat_product.class.to_s}:#{@current_user.id}"].to_i > 0, spend_obi: "5" }).update({created_at: f.created_at.to_s(:db)}) and f.owhat_product_type.match(/Welfare/) ? h.merge({obi: '发布福利得O元', empirical_value: '发布福利得经验值'}) : h.merge!({ obi: '做任务得O!元为花费金额的1%', empirical_value: '做任务得经验值同花费金额' })
                case f.owhat_product.class.to_s
                when 'Shop::Subject'
                  h.update(participator: Redis.current.get("subject:#{f.owhat_product.id}:read_subject_participator").to_i)
                when 'Shop::Media'
                  h.update(participator: Redis.current.get("media:#{f.owhat_product.id}:read_subject_participator").to_i)
                end
                h
              }
            end
          end
          [feeds, count]
        end
      else
        feeds = []
        count = 0
      end
      welf_count = count - other_user.task_count('welfare')
      success(data: {
        feeds: feeds,
        has_next: feeds.size == per_page ,
        count: count,
        share_url: "#{Rails.application.routes.default_url_options[:host]}/home/users/#{params[:user_id]}",
        user: {
          id: other_user.id,
          name: other_user.name,
          level: other_user.level,
          pic: other_user.picture_url,
          image: other_user.image.try(:picture_url) || Core::Image.published.first.tries(:picture_url),
          signature: other_user.signature,
          is_followed: user.friendship[other_user.follow_key].to_i,
          identity: other_user.identity,
          verified: other_user.verified,
          balance_account: other_user.balance_account, #账户余额
          welfare_count: other_user.task_count('welfare'), #发布福利总数
          shop_count: other_user.verified? ? other_user.task_count('task') : welf_count < 0 ? 0 : welf_count, #发布任务总数
          participator: other_user.shop_tasks.map{|task| task.participator}.sum,
        },
        sign: (other_user.privacy || other_user.verified?) ? (Redis.current.get("User:Milestone:#{other_user.id}") ? eval(Redis.current.get("User:Milestone:#{other_user.id}")) : nil) : nil
      })
    end

    get :user_personal_center do
      return fail(0, "用户不存在!") unless @current_user.present?
      user = {
        id: @current_user.id,
        name: @current_user.name,
        pic: @current_user.picture_url,
        birthday: @current_user.birthday,
        role: @current_user.identity,
        level: @current_user.level.to_i,
        signature: @current_user.signature,
        follow_count: @current_user.follow_count,
        followers_count: @current_user.followers_count,
        privacy: @current_user.privacy,
        cart_count: @current_user.tries(:cart, :my_carts, :size),
        phone: @current_account.phone,
        email: @current_account.email,
        image: @current_user.tries(:image, :picture_url) || Core::Image.published.first.tries(:picture_url),
        is_password: @current_account.crypted_password.present?,
        about_url: "https://itunes.apple.com/cn/app/owhat-zui-qiang-fen-si-ying/id910606347?mt=8",
        connections: @current_account.connections.map do |c|
          {
            id: c.id,
            site: c.site
          }
        end
      }
      success(data: { user: user })
    end

    params do
      optional :category, type: String
      optional :is_completed, type: Boolean
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :my_welfares do
      if params[:is_completed]
        # Shop::Task.published.welfares.includes(:expens).where(core_expens: { user_id: @current_user.id }).order("core_expens.created_at desc")
        expens = @current_user.expens
        expens = expens.where(resource_type: ['Welfare::Letter', 'Welfare::Voice']) unless version_compare
        expens = expens.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        count = expens.total_entries
        has_next = expens.next_page.to_i > 0
        welfares = expens.map do |expen|
          {
            id: expen.task_id,
            title: expen.tries(:task, :title),
            pic: expen.tries(:task, :list_pic),
            shop_type: expen.resource_type,
            shop_id: expen.resource_id,
            completed_at: expen.tries(:created_at, :to_s, &:db),
            created_at: expen.tries(:task, :created_at, :to_s, &:db),
            participator: expen.tries(:resource, :participator).to_i
          }
        end
        success(data: { welfares: welfares.as_json, count: count, has_next: has_next})
      else
        welfares = @current_user.feeds.welfares.order(created_at: :desc)
        welfares = welfares.where(shop_type: ['Welfare::Letter', 'Welfare::Voice']) unless version_compare
        welfares = welfares.where(shop_type: Shop::Task::CATEGORY[params[:category]]) if %w(letter voice event product).include?(params[:category])
        welfares = welfares.select("shop_tasks.id, shop_tasks.title, shop_tasks.pic, shop_tasks.guide, shop_tasks.shop_type, shop_tasks.shop_id, shop_tasks.created_at, shop_tasks.user_id").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        count = welfares.total_entries
        has_next = welfares.next_page.to_i > 0
        welfares = welfares.map do |welfare|
          {
            id: welfare.id,
            title: welfare.title,
            pic: welfare.list_pic,
            guide: welfare.guide,
            shop_type: welfare.shop_type,
            shop_id: welfare.shop_id,
            completed_at: welfare.expens.find_by(user_id: @current_user.id).tries(:created_at, :to_s, &:db),
            is_complete: welfare.task_state["#{welfare.shop_type}:#{@current_user.id}"].to_i > 0,
            created_at: welfare.created_at.tries(:to_s, &:db),
            participator: welfare.tries(:shop, :participator).to_i,
            obi: 0,
            user: {
              id: welfare.user_id,
              name: welfare.tries(:user, :name)
            }
          }
        end
        success(data: { welfares: welfares.as_json, count: count, has_next: has_next})
      end
     end

    desc "获取融云token"
    params do
      requires :user_id, type: Integer
    end
    get :get_rongyun_token do
      user = Core::User.find_by(id: params[:user_id])
      options = {
        user_id:    user.id,
        name:       user.name,
        avatar_url: user.picture_url
      }
    success ({data: Rongcloud::AccessToken.get_token(options)})
    end

    desc "广播推送点击率统计"
    params do
      requires :send_id, type: Integer
    end
    post :open_send_statistics do
      notifi_send = Notification::Send.find_by(id: params[:send_id])
      return fail(0, '没有这条广播消息') if notifi_send.blank?
      send_staitc = Notification::SendStatistic.new(send_id: params[:send_id], uid: params[:uid], platform: params[:from_client])
      if send_staitc.save
        CoreLogger.info(logger_format(api: "open_send_statistics", send_id: params[:send_id], uid: params[:uid], platform: params[:from_client]))
      end
      success({data: true})
    end

    desc "用户钱包"
    params do
      requires :uid, type: Integer
    end

    get :get_my_wallets do
      user = Core::User.find_by(id: params[:uid])
      balance_account = user.verified ? user.balance_account : 0
      obi_account = user.obi
      empirical_account = user.empirical_value
      success({data: {verified: user.verified, balance_account: balance_account, obi_account: obi_account, empirical_account: empirical_account}})
    end

    desc "钱包明细"
    params do
      requires :uid, type: Integer
      requires :type, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :wallet_index do
      user = Core::User.find_by(id: params[:uid])
      per_page = params[:per_page].present? ? params[:per_page] : 10
      if params[:type] == 'RMB'
        #购买和提现订单
        @rmb_detail = Shop::OrderItem.find_by_sql("SELECT `o`.id, `o`.is_income, `o`.owhat_product_id, `o`.owhat_product_type, `o`.created_at, `o`.payment FROM `shop_order_items` AS `o` WHERE `o`.owner_id = #{user.id} AND `o`.status = 2 UNION ALL
          SELECT `f`.id, `f`.is_income, `f`.shop_funding_id, `f`.shop_funding_type, `f`.created_at, `f`.payment FROM `shop_funding_orders` AS `f`  WHERE `f`.owner_id = #{user.id} AND `f`.status = 2 UNION ALL
          SELECT `w`.id, `w`.is_income, `w`.task_id, `w`.task_type, `w`.created_at, `w`.amount FROM `core_withdraw_orders` AS `w` WHERE `w`.requested_by = #{user.id} AND `w`.status = 3 LIMIT #{per_page} OFFSET #{(params[:page] ? params[:page] - 1 : 0)*per_page || 0};")
      end

      SELECT m.id id, m.name, m.phone, f.created_at, count(s.id) shop_count, c.name company_name, ifnull(sum(t.price),0) total_amount FROM mind_users m INNER join fx_users f on f.id = m.id left join fx_infos i on i.user_id=f.id left join core_branch_companies c on c.id = f.company_id inner join mind_shops s on s.mind_id = m.id left join (select shop_id, sum(price) price from shop_trades where payment_status = 'success' group by shop_id) t on t.shop_id = s.id where f.created_at between '2017-01-01' and '2017-10-01' and f.company_id = 137 GROUP BY m.id


      SELECT m.id id, m.name, m.phone, f.created_at, count(s.id) shop_count, c.name company_name, ifnull(sum(t.price),0) total_amount FROM mind_users m INNER join fx_users f on f.id = m.id left join fx_infos i on i.user_id=f.id left join core_branch_companies c on c.id = f.company_id inner join mind_shops s on s.mind_id = m.id left join (select shop_id, sum(price) price from shop_trades where payment_status = 'success' group by shop_id) t on t.shop_id = s.id where f.created_at between '2017-01-01' and '2017-10-01' and f.company_id = 137 GROUP BY m.id

      sql1 = "SELECT `o`.task_id, `o`.user_id AS user_id, `o`.task_type, `o`.obi, `o`.from, `o`.is_income, `o`.created_at FROM `core_task_awards` AS `o` WHERE `o`.user_id = #{user.id} AND `o`.active = 1"
      sql2 = "SELECT `f`.resource_id, `f`.user_id AS user_id, `f`.resource_type, `f`.amount, `f`.status, `f`.is_income, `f`.created_at FROM `core_expens` AS `f`  WHERE `f`.user_id = #{user.id} "
      @obi_detail = Core::TaskAward.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) ORDER BY created_at DESC LIMIT #{per_page} OFFSET #{(params[:page] ? params[:page] - 1 : 0)*per_page || 0};")
      # count = Shop::OrderItem.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) UNION ALL (#{sql3})").count
      # @obi_detail = Core::TaskAward.active.where(user_id: params[:uid]).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10).as_json
      success({data: { rmb_detail: @rmb_detail, obi_detail: @obi_detail }})
    end

    params do
      requires :user_ids, type: String
    end
    get :users_list do
      users = Core::User.active.where(id: params[:user_ids].split(',').compact.uniq).select("id, name, pic, identity")
      users = users.map do |user|
        {
          id: user.id,
          name: user.name,
          pic: user.picture_url,
          identity: user.identity
        }
      end
      success({ data: { users: users.as_json } })
    end

    params do
      requires :user_id, type: Integer
    end
    get :user_verified_info do
      user = Core::User.find_by(id: params[:user_id])
      return fail(0, "没有该用户") if user.blank?
      hash = {
        id: user.id,
        name: user.name,
        identity: user.identity,
        pic: user.picture_url,
        image: user.image.try(:picture_url) || Core::Image.published.first.tries(:picture_url),
        friendship: @current_user.friendship[user.follow_key].to_i,
        follow_count: user.follow_count,
        followers_count: user.followers_count,
        signature: user.signature,
      }
      success({ data: { user: hash } })
    end

    params do
      requires :uid, type: Integer
      requires :welfare_id, type: Integer
      requires :type, type: String
    end
    get :user_welfare_complete do
      welfare = if params[:type].to_s == 'letter'
        Welfare::Letter.find_by id: params[:welfare_id]
      else
        Welfare::Voice.find_by id: params[:welfare_id]
      end
      return fail(0, "该福利不存在") unless welfare.present?
      complete = welfare.shop_task.task_state["#{welfare.class.to_s}:#{@current_user.id}"].to_i > 0 || @current_user.id == welfare.user_id
      success({ data: { complete: complete, obi: @current_user.obi, welfare_id: params[:welfare_id], welfare_type: params[:type] } })
    end

    desc '玩转owhat'
    params do
      requires :uid, type: Integer
    end
    get :play_owhat do
      user = Core::User.find_by(id: params[:uid])
      success(data: {
        user: {
          id: user.id,
          title: user.current_level_name,
          next_level_need: user.next_level_need,
          name: user.name,
          level: user.level,
          pic: user.picture_url,
          image: user.image.try(:picture_url),
          identity: user.identity,
          verified: user.verified,
          obi_account: user.obi, #obi
          empirical_value: user.empirical_value,
          is_pic_changed: user.pic ? true : false,
          is_name_changed: user.name ? true : false,
          is_sign_changed: user.signature ? true : false,
          is_mobile_changed: @current_account.phone ? true : false,
          is_social_changed: @current_account.connections.size > 0 ? true : false,
          is_birth_changed: user.birthday ? true : false,
          is_address_changed: user.addresses.size > 0 ? true : false,
          is_descri_changed: user.signature ? true : false
        }
      })
    end

    desc '设置自动分享状态'
    params do
      requires :uid, type: Integer
      requires :auto_share, type: String
      optional :order_no, type: String
      optional :category, type: String
    end
    post :set_auto_share do
      return fail(0, "该用户不存在") if @current_user.blank?
      if @current_user.update_attributes(is_auto_share: params[:auto_share] == 'yes')
        CoreLogger.info(logger_format(api: "set_auto_share", auto_share: params[:auto_share]))
        ShareWorker.perform_async(params[:order_no], params[:category]) if params[:auto_share] == 'yes' && params[:order_no].present?  && params[:category].present?
        success(data: true)
      else
        fail(0, "设置失败")
      end
    end

  end
end
