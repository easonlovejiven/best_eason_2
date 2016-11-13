class Home::ConnectionsController < Home::ApplicationController
  def index
    flash[:notice] = nil
    @connection = Core::Connection.active.find_by id: params[:connection_id]
    unless @connection && params[:sign] == Digest::MD5.hexdigest("#{@connection.id}#{OAUTH_CONFIG[@connection.site]['secret']}#{@connection.token}").downcase
      render text: { error: '参数错误'}
      return
    end
  end

  def new
    site = params[:site].to_s
    redirect = params[:redirect].to_s
    config = OAUTH_CONFIG[site]

    callback = "http://#{request.domain(999)}/connections/callback?site=#{CGI::escape(site)}&redirect=#{CGI::escape(redirect)}&type=#{CGI::escape(params[:type].to_s)}"
    case site
    when 'weibo'
      options = {
        client_id: config['key'].to_s,
        forcelogin: true,
        redirect_uri: callback,
        scope: 'all'
      }
      authorize_url = "#{config['site']}#{config['authorize_path']}?#{options.map{|k, v|"#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}"
    when 'qq'
      options = {
        response_type: 'code',
        client_id: config['key'],
        redirect_uri: callback,
        state: callback
      }
      authorize_url = "#{config['site']}#{config['authorize_path']}?#{options.map{|k,v| "#{k}=#{CGI::escape(v)}"}.join('&')}"
    when 'wechat'
      scope = params[:scope].blank? ? 'snsapi_login' : params[:scope] # 改动 1，scope值的两种设置
      options = {
        appid: config['key'],
        redirect_uri: push_param(callback, "scope=#{scope}"),
        response_type: 'code',
        # scope: 'snsapi_userinfo',
        scope: scope, # 改动 2
      }
      authorize_url = "#{config['authorize_path']}?#{options.map{|k, v|"#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}#wechat_redirect"
    when 'baidu'
      # callback = "http://www.owhat.cn/connections/callback?site=#{CGI::escape(site)}&redirect=#{CGI::escape(redirect)}"
      callback="http://www.owhat.cn/connections/callback?site=baidu&redirect=%2F"
      Rails.logger.info callback
      options = {
        response_type: 'code',
        client_id: config['key'],
        redirect_uri: callback,
        force_login: 1,
        confirm_login: 1,
      }
      authorize_url = "#{config['site']}#{config['authorize_path']}?#{options.map{|k, v|"#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}"
    end
    respond_to do |format|
      format.html { redirect_to authorize_url if authorize_url }
      format.json { render text: { 'url' => authorize_url } }
    end
  end

  def callback
    site = params[:site].to_s
    redirect = params[:redirect].to_s
    config = OAUTH_CONFIG[site]
    callback = "http://#{request.domain(999)}/connections/callback?site=#{CGI::escape(site)}&redirect=#{CGI::escape(redirect)}"
    case site
    when 'weibo'
      options = { client_id: config['key'].to_s, client_secret: config['secret'].to_s, grant_type: 'authorization_code', code: params[:code].to_s, redirect_uri: callback }
      resp_token = ActiveSupport::JSON.decode(HTTParty.post("#{config['site']}#{config['access_token_path']}", body: options).body)
      # resp_info = ActiveSupport::JSON.decode(HTTParty.post("#{config['site']}#{config['get_token_path']}", body: {access_token: resp_token['access_token']}).body)
      info = ActiveSupport::JSON.decode(HTTParty.get("https://api.weibo.com/2/users/show.json", query: {access_token: resp_token['access_token'], uid: resp_token['uid']}).body.strip_emoji)
      HTTParty.get("#{config['site']}#{config['revoke_path']}", body: {access_token: resp_token['access_token']})
      Rails.logger.info(info)
      redirect_to popup_connections_path and return if info['id'].blank?
      @connection = find_connection(site, info['id'], info['name'])
      # @connection = Core::Connection.active.find_by(site: site, identifier: info['id'])
      @connection.name = info['name']
      @connection.sex = info['gender'].blank? ? nil : info['gender'] == 'm' ? 'male' : 'female'
      @connection.pic = info['avatar_large']
      @connection.token = resp_token['access_token']
      @connection.expired_at = Time.now + 29.days
      @connection.data = info
    when 'wechat'
      options = { appid: config['key'].to_s, secret: config['secret'].to_s, code: params[:code].to_s, grant_type: 'authorization_code' }
      uri = URI.parse(config['site'])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http_request = Net::HTTP::Get.new("#{config['access_token_path']}?#{options.map{|k, v|"#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}")
      response = JSON.parse http.request(http_request).body.strip_emoji

      redirect_to popup_connections_path and return if response['errcode'].present?
      # 改动3，根据 params[:type] 的值，分为 只取open_id 和 用户授权 两种情况。后者需要保存 connection，前者则只需跳转页面即可。
      if params[:scope].to_s == 'snsapi_base' && params[:type].to_s == 'binding'
        redirect_to(redirect.present? && push_param(redirect, "open_id=#{response['openid']}") || new_session_path) and return
      end

      user_info_options = response.slice('access_token', 'openid').merge(lang: 'zh_CN')
      request_user = Net::HTTP::Get.new("#{config['user_info_path']}?#{user_info_options.map{|k, v|"#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}")
      resp_user_info = JSON.parse http.request(request_user).body
      redirect_to(redirect.present? && redirect || '/') and return if resp_user_info['errcode'].present?
      raise 'invalid identifier' if resp_user_info['openid'].blank?
      @connection = find_connection(site, resp_user_info['openid'].to_s, resp_user_info['nickname'].to_s)
      @connection.attributes = {
        token: response['access_token'].to_s,
        refresh_token: response['refresh_token'].to_s,
        expired_at: Time.now + response['expires_in'].to_i,
        data: resp_user_info,
        name: resp_user_info['nickname'].to_s,
        pic: resp_user_info['headimgurl'].to_s,
        sex: { '0' => nil, '1' => 'male', '2' => 'female' }[resp_user_info['sex'].to_s],
      }
    when 'qq'
      options = { grant_type: 'authorization_code', client_id: config['key'], client_secret: config['secret'], code: params[:code], redirect_uri: callback }
      token_url = "#{config['site']}#{config['request_token_path']}?#{options.map{|k,v| "#{k}=#{CGI::escape(v)}"}.join('&')}"
      resp_token = HTTParty.get(token_url).body.split("&").map{|str| str.split("=") }.map{|k,v| {k => v}}.inject(&:merge)
      resp_openid = JSON.parse(HTTParty.get("#{config['site']}#{config['access_token_path']}?access_token=#{resp_token['access_token']}").body.match(/\{.*\}/).to_s)
      redirect_to popup_connections_path and return if resp_openid['openid'].blank?
      resp = JSON.parse(HTTParty.get("https://graph.qq.com/user/get_user_info?access_token=#{resp_token['access_token']}&oauth_consumer_key=#{config['key']}&openid=#{resp_openid['openid']}").body.strip_emoji)
      @connection = find_connection('qq', resp_openid['openid'], resp['nickname'])
      @connection.token = resp_token['access_token']
      @connection.data = resp
      @connection.pic = resp['figureurl_qq_2']
      @connection.name = resp['nickname']
      @connection.sex = (resp['gender'] == '男') ? 'male' : 'female'
    when 'baidu'
      callback = "http://www.owhat.cn/connections/callback?site=baidu&redirect=%2F"
      options = { grant_type: 'authorization_code', code: params[:code], client_id: config['key'], client_secret: config['secret'], redirect_uri: callback }
      token_url = "#{config['site']}#{config['access_token_path']}?#{options.map{|k,v| "#{k}=#{CGI::escape(v)}"}.join('&')}"
      uri = URI.parse(token_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.ssl_version = 'TLSv1'
      # resp_token = JSON.parse(HTTParty.get(token_url).body)
      resp_token = JSON.parse(http.get(uri.request_uri).body)
      raise 'access_token identifier' if resp_token['access_token'].blank?
      user_info_path = "#{config['site']}#{config['user_info_path']}?access_token=#{resp_token['access_token']}"
      uri = URI.parse(user_info_path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.ssl_version = 'TLSv1'
      resp = JSON.parse(http.get(uri.request_uri).body.match(/\{.*\}/).to_s.strip_emoji)
      # resp = JSON.parse(HTTParty.get().body.match(/\{.*\}/).to_s.gsub(/[\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E7}-\u{1F1EC}\u{1F1EE}-\u{1F1F0}\u{1F1F3}\u{1F1F5}\u{1F1F7}-\u{1F1FA}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F320}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}]/,''))
      raise 'invalid identifier' if resp['userid'].blank?
      @connection = find_connection('baidu', resp['userid'], resp['username'])
      @connection.token = resp_token['access_token']
      @connection.data = resp
      @connection.pic = "http://himg.bdimg.com/sys/portrait/item/#{resp['portrait']}.jpg"
      @connection.name = resp['username']
      @connection.sex = (resp['sex'] == '1') ? 'male' : 'female'
    end
    ActiveRecord::Base.transaction do
      if @current_account
        if @connection.id
          flash[:notice] = '该用户已绑定'
          respond_to do |format|
            format.html { redirect_to params[:redirect] || root_path }
            format.json { render json: @resource }
          end
          return
        end
        @connection.account = @current_account
        @connection.save!
        flash[:notice] = '绑定成功'
        redirect_to params[:redirect] || root_path
      else
        if @connection.save!
          unless @connection.account && (@connection.account.phone.present? || @connection.account.email.present?)
            sign = Digest::MD5.hexdigest("#{@connection.id}#{config['secret']}#{@connection.token}").downcase
            CoreLogger.info(controller: 'Home::Connections', action: 'callback', connection_id: @connection.try(:id), type: "account_is_nil", current_user: @current_user.try(:id))
            redirect_to connections_path(connection_id: @connection.id, sign: sign)
            return
          else
            self.current_account = @connection.account
            CoreLogger.info(controller: 'Home::Connections', action: 'callback', connection_id: @connection.try(:id), type: "account_is_exist", current_user: @current_user.try(:id))
            flash[:notice] =  "登录成功"
            redirect_to params[:redirect] || root_path
          end
        else
          flash[:notice] = '登录失败'
          redirect_to new_session_path
        end
      end
    end
  rescue Exception => e
    SendEmailWorker.perform_async(6, "登陆错误#{e}, #{@connection.account.id}", "core_connection")
    return render text: { error: "登陆异常错误，请联系客服，客服电话4008980812"}
    #flash[:notice] = '我们暂不支持带符号表情的第三方用户注册登录，请去掉您的表情符号吧。'
    #redirect_to new_session_path
  end

  def list
    flash[:notice] = nil
    @connection = Core::Connection.active.find_by id: params[:connection_id]
    @account = Core::Account.active.find_by id: params[:account_id]
    if @connection.account_id == @account.id
      render json: { error: '已绑定过'}
      return
    end
    unless @connection && @account && params[:sign] == Digest::MD5.hexdigest("list#{@account.id}#{@connection.id}#{OAUTH_CONFIG[@connection.site]['secret']}#{@connection.token}").downcase
      render json: { error: '参数错误'}
      return
    end
  end

  def binding
    @connection = Core::Connection.active.find_by id: params[:id]
    @account = Core::Account.active.find_by id: params[:account_id]
    unless @connection && @account && params[:sign] == Digest::MD5.hexdigest("binding#{@account.id}#{@connection.id}#{OAUTH_CONFIG[@connection.site]['secret']}#{@connection.token}").downcase
      render text: { error: '参数错误'}
      return
    end
    if @connection.account && (@connection.account.phone.present? || @connection.account.email.present?)
      render text: { error: '已绑定过账户，不能重复操作'}
      return
    end
    # 放队列加事务
    if @connection.account.present?
      database_transaction do
        Shop::OrderItem.where(user_id: @connection.account_id).each do |o|
          o.update(user_id: @account.id)
        end
        Shop::Order.where(user_id: @connection.account_id).each do |o|
          o.update(user_id: @account.id)
        end
        Shop::FundingOrder.where(user_id: @connection.account_id).each do |o|
          o.update(user_id: @account.id)
        end
        Core::Punch.where(user_id: @connection.account_id).each do |o|
          o.update(user_id: @account.id)
        end
        Core::Expen.where(user_id: @connection.account_id).each do |o|
          o.update(user_id: @account.id)
        end
        @connection.account.user.update(old_uid: @connection.account.user.old_uid) if @connection.account && @connection.account.user.present? &&  @connection.account.user.old_uid.present? #此处更新old_uid
      end
    end

    if @connection.update_attributes(account_id: @account.id)
      self.current_account = @connection.account
      flash[:notice] = "#{@current_user.try(:name)}绑定成功"
      CoreLogger.info(controller: 'Home::Connections', action: 'binding', connection_id: @connection.try(:id), account_id: @account.try(:id), current_user: @current_user.try(:id))
      respond_to do |format|
        format.html { redirect_to params[:redirect] || root_path }
        format.json { render json: { url: params[:redirect] || root_path }}
      end
    else
      respond_to do |format|
        format.html { redirect_to new_session_path }
        format.json   { raise "创建失败"}
      end
    end
  end

  def popup
    render layout: false
  end

  def destroy
    @connection = Core::Connection.active.find_by(id: params[:id])

    if @current_account.connections.count < 2 && @current_account.crypted_password.blank?
      flash[:notice] = '已用该账户登录，不容许解绑'
      redirect_to edit_home_users_path
      return
    end
    if @current_user.nil? || @current_user.id != @connection.account_id
      flash[:notice] =  '解除绑定失败'
      redirect_to edit_home_users_path
      return
    end
    # @connection.update_attributes(active: false)
    @current_account.connections.active.where(site: @connection.site).each do |a|
      a.update(active: false)
    end

    respond_to do |format|
      flash[:notice] =  '解除绑定成功'
      CoreLogger.info(controller: 'Home::Connections', action: 'destroy', connection_id: @connection.try(:id), account_id: @current_account.try(:id), current_user: @current_user.try(:id))
      format.html { redirect_to edit_home_users_path }
      format.json { render json: { url: params[:redirect] || '/' } }
    end
  end

  def new_share
    site = params[:site].to_s
    redirect = params[:redirect].to_s
    config = OAUTH_CONFIG[site]
    callback = "http://#{request.domain(999)}/connections/weibo_share_callback?site=#{CGI::escape(site)}&redirect=#{CGI::escape(redirect)}&type=#{CGI::escape(params[:type].to_s)}&order_no=#{CGI::escape(params[:order_no].to_s)}&category=#{CGI::escape(params[:category].to_s)}"
    case site
    when 'weibo'
      options = {
        client_id: config['key'].to_s,
        forcelogin: true,
        redirect_uri: callback,
        scope: 'all'
      }
      authorize_url = "#{config['site']}#{config['authorize_path']}?#{options.map{|k, v|"#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}"
    end
    respond_to do |format|
      format.html { redirect_to authorize_url if authorize_url }
      format.json { render text: { 'url' => authorize_url } }
    end
  end

  def weibo_share_callback
    site = params[:site].to_s
    redirect = params[:redirect].to_s
    config = OAUTH_CONFIG[site]
    callback = "http://#{request.domain(999)}/connections/weibo_share_callback?site=#{CGI::escape(site)}&redirect=#{CGI::escape(redirect)}&order_no=#{CGI::escape(params[:order_no].to_s)}&category=#{CGI::escape(params[:category].to_s)}"
    case site
    when 'weibo'
      options = { client_id: config['key'].to_s, client_secret: config['secret'].to_s, grant_type: 'authorization_code', code: params[:code].to_s, redirect_uri: callback }
      resp_token = ActiveSupport::JSON.decode(HTTParty.post("#{config['site']}#{config['access_token_path']}", body: options).body)
      info = ActiveSupport::JSON.decode(HTTParty.get("https://api.weibo.com/2/users/show.json", query: {access_token: resp_token['access_token'], uid: resp_token['uid']}).body.strip_emoji)
      HTTParty.get("#{config['site']}#{config['revoke_path']}", body: {access_token: resp_token['access_token']})
      Rails.logger.info(info)
      redirect_to popup_connections_path and return if info['id'].blank?
      @connection = find_connection(site, info['id'], info['name'])
      @connection.name = info['name']
      @connection.sex = info['gender'].blank? ? nil : info['gender'] == 'm' ? 'male' : 'female'
      @connection.pic = info['avatar_large']
      @connection.token = resp_token['access_token']
      @connection.expired_at = Time.now + 29.days
      @connection.data = info
    end
    if @current_account
      return redirect_to (params[:redirect] || root_path), notice: '该账号已绑定' if @connection.account_id.present? && @connection.account_id != @current_account.id
      @connection.account = @current_account unless @connection.account_id.present?
      if @connection.save
        @current_user.update(is_auto_share: true)
        ShareWorker.perform_async(params[:order_no], params[:category]) if params[:order_no].present? && params[:category].present?
        CoreLogger.info(controller: 'Home::Connections', action: 'weibo_share_callback', connection_id: @connection.try(:id), order_no: params[:order_no], category: params[:category], account_id: @current_account.try(:id))
        redirect_to (params[:redirect] || root_path), notice: '设置自动分享成功'
      else
        redirect_to (params[:redirect] || root_path), notice: '设置自动分享失败'
      end
    else
      redirect_to new_session_path, notice: '未登录'
    end
  end

  private

  def find_connection site, identifier, name
    connection = Core::Connection.active.find_or_initialize_by(site: site, identifier: identifier)
  end

  def authorized?
    true
  end

  # 组装个参数进去
  def push_param(url, param_str)
    arr = url.split('?')
    arr[0] + '?' + ( (arr[1] && arr[1].split('&').push(param_str).join('&')) || param_str )
  end
end
