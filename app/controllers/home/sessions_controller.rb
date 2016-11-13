class Home::SessionsController < Home::ApplicationController
  def new
    logout_killing_session!
    if params[:connection_id].present?
      @connection = Core::Connection.active.find_by id: params[:connection_id]
      unless @connection && params[:sign] == Digest::MD5.hexdigest("session#{@connection.id}#{OAUTH_CONFIG[@connection.site]['secret']}#{@connection.token}").downcase
        return render text: { error: '参数不合法'}
      end
    end
  end

	def create
		logout_keeping_session!
		if params[:category] == 'qr_code'
			raise '操作错误' unless Digest::MD5.hexdigest("#{params[:uid]}OTjnsYw76IR98#{params[:time]}").downcase == params[:sign]
			raise '已超时' unless params[:time].to_i > 10.minute.ago.to_i
			@account = Core::Account.active.find_by(id: params[:uid])
    else
      @account = Core::Account.search_by_params(params.require(:account).permit(:id, :login, :email, :phone))
      if params[:connection_id].present?
        @connection = Core::Connection.active.find_by id: params[:connection_id]
        unless @connection && params[:connection_sign] == Digest::MD5.hexdigest("login#{@connection.id}#{OAUTH_CONFIG[@connection.site]['secret']}#{@connection.token}").downcase
          return render json: { error: '参数不合法'}
        end
      end
		end

		if @account && (params[:category] == 'qr_code' || @account.authenticated?(params[:account][:password]))
      #第三方登录绑定账户
      if @connection
        if @connection.site== 'weibo' && @account.connections.where(site: 'weibo').active.count > 0
          return render json: { error: '微博不能绑定两个账户'}
        end
        if @account.connections.active.where(site: @connection.site).count > 0
          return render json: { url: list_connections_path(connection_id: @connection.id, account_id: @account.id, sign: Digest::MD5.hexdigest("list#{@account.id}#{@connection.id}#{OAUTH_CONFIG[@connection.site]['secret']}#{@connection.token}").downcase)}
        else
          if @connection.account.present?
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
          @connection.update_attributes!(account_id: @account.id)
        end
      end
      self.current_account = @account
			# handle_remember_cookie! (params[:remember_me] == "1")
      #判断用户是否在当日登陆过
			unless Redis.current.get("core_user_login_by_#{@account.user.id}_at_#{Time.now.beginning_of_day}")
				Redis.current.set("core_user_login_by_#{@account.user.id}_at_#{Time.now.beginning_of_day}", 1)
				AwardWorker.perform_async(@account.user.id, @account.user.id, @account.user.class.name, 1, 0, 'self', :award )
			end
			# @account.v3_count.increment(1)
      flash[:notice] = "#{@account.user.try(:name)}登录成功"
      CoreLogger.info(controller: 'Home::Sessions', action: 'create', account_id: @account.try(:id), connection_id: @connection.try(:id), current_user: @current_user.try(:id))
			respond_to do |format|
				# format.html { redirect_to(@account.v3_count.to_i > 1 ? (params[:redirect] || root_path) : welcome_home_home_index_path) }
        format.html { redirect_to(params[:redirect] || root_path) }
				format.json { render text: { url: params[:redirect] || root_path }.to_json }
			end
		else
			logger.warn "Failed login for '#{params[:account][:login] || params[:account][:email] || params[:account][:phone]}' from #{request.remote_ip} at #{Time.now}"
			@login       = params[:login]
			@remember_me = params[:remember_me]

			# flash[:notice] = "用户名或密码输入错误"

			respond_to do |format|
				format.html { render action: :new }
				format.json { raise "用户名或密码输入错误" }
			end
		end
	end

	def destroy
    CoreLogger.info(controller: 'Home::Sessions', action: 'destroy', current_user: @current_user.try(:id))
		logout_killing_session!
		redirect_to params[:redirect].match(/\/manage/) ? params[:redirect] : new_session_path
	end

	private

	def authorized?
		true
	end
end
