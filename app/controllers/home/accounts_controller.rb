class Home::AccountsController < Home::ApplicationController

  def new
    if params[:connection_id].present?
      @connection = Core::Connection.active.find_by id: params[:connection_id]
      if @connection.try(:account) && (@connection.account.phone.present? || @connection.account.email.present?)
        render json: { error: '该账户已绑定' }
      end
    end
  end

	def create
		logout_keeping_session!

		raise "未填邮箱或手机" if !params[:account] || params[:account][:email].blank? && params[:account][:phone].blank?
		raise "邮箱或手机号已注册" if Core::Account.active.search_by_params(params.require(:account).permit(:login, :email, :phone))
    # @list = Redis::List.new "account_ip_created_by_#{request.remote_ip}"
    # @list << request.remote_ip
    # raise "you are outing!!!" if @list.size > 35
    @account = Core::Account.new(params.require(:account).permit(:email, :phone, :password, :password_confirmation, :client))
    raise '短信或邮箱验证码错误' unless @account.make_phone_verify_code(params[:captcha])
    if params[:connection_id].present?
      @connection = Core::Connection.active.find_by id: params[:connection_id]
      unless @connection && params[:sign] == Digest::MD5.hexdigest("account#{@connection.id}#{OAUTH_CONFIG[@connection.site]['secret']}#{@connection.token}").downcase
        return render json: { error: '参数不合法'}
      end
    end

		success = database_transaction do
      @account.client = 'web'
      if @connection.try(:account)
        if @connection.account.phone.present? || @connection.account.email.present?
          render text: { error: '已绑定过账户，不能重复操作'}
          return
        end
        @connection.account.update_attributes!(params.require(:account).permit(:email, :phone, :password, :password_confirmation, :client))
        @account = @connection.account
      else
        @account.make_activation_code
        @lock = Redis::Lock.new("account_#{@account.phone || @account.email}", :expiration => 15, :timeout => 0.1)
        @lock.lock do
          @account.save!
          @user = Core::User.new
          @user.id = @account.id
          @user.update_attributes!(name: "O星人#{SecureRandom.urlsafe_base64(6)}")
          @connection.update_attributes!(account_id: @account.id) if @connection
          omei = Core::Star.find_by id: 423
          @user.follow_and_update_cache(omei) if omei
        end
      end
		end

		if success
			self.current_account = @account# if @account.email && !@account.password.blank?
			@account.send_active_email if @account.has_email
			# @account.v3_count.increment(1)
      @user = @account.user
      # TaskWorker.perform_async(@user.id, 'user')
      flash[:notice] = "注册成功"
      CoreLogger.info(controller: 'Home::Accounts', action: 'create', account: @account.as_json)
			respond_to do |format|
				format.html { redirect_to request.referer || '/' }
				format.json
			end
		else
      # flash[:notice] = "注册失败"
			respond_to do |format|
				format.html { redirect_to '/' }
				format.json   { raise "创建失败"}
			end
		end
	end

	def send_phone_code
		unless verify_rucaptcha?(params[:_rucaptcha])
      render json: {code: 601, error: '图片验证码错误'}
      return
    end
    res = Core::MobileCode.send_code(params[:phone], 'register', params[:type], 10)
    if res
      if res[:ret]
        render success: true
      elsif res[:error] == 'Send SMS messages beyond the limit of five per day.'
        render json: { code: 601, error: "每天每个手机号限制发送5条，您已经超出5条！"}
      else
        render json: res
      end
    else
      render json: res
    end
  end

  def send_email_code
    unless verify_rucaptcha?(params[:_rucaptcha])
      render json: {code: 601, error: '图片验证码错误'}
      return
    end
    res = Core::MobileCode.send_email_code(params[:email], 'register', 60)
    if res[:ret]
      render success: true
    else
      render json: res
    end
  end

  # def edit_password
  #   raise '没有权限' if params[:id].to_i != @current_user.id
  # 	@account = Core::Account.find(params[:id])
  # end

  def new_password
    # raise '没有权限' if params[:id].to_i != @current_user.id
    @account = Core::Account.find(params[:id])
  end

  def update_password
    @account = Core::Account.active.search_by_params(params.require(:account).permit(:login, :email, :phone).merge(id: params[:id]))
    password = params[:account] && params[:account][:password]
		old_password = params[:account] && params[:account][:old_password]
    reset_code = params[:account] && params[:account][:captcha]
    raise '没有权限' if old_password && @account.id != @current_user.id
		unless password && old_password && !old_password.nil? && @account.authenticated?(old_password) || password && reset_code && !reset_code.blank? && @account.reset_code_valid?(reset_code)
			respond_to do |format|
				format.html { redirect_to request.referer || '/' }
				format.json { render json: { error: "当前密码输入错误" } }
			end
			return
		end

		@account.password = @account.password_confirmation = password
		@account.remember_token = nil
		@account.remember_token_expires_at = nil

		if @account.save(validate: false)
      session[:user_id] = nil
      session[:user_login_on] = nil
      CoreLogger.info(controller: 'Home::Accounts', action: 'update_password', user_id: @account.try(:id), current_user: @current_user.try(:id))
			respond_to do |format|
				format.html { redirect_to request.referer || "/" }
				format.json { render json: { success: true } }
			end
		else
			respond_to do |format|
				format.html { redirect_to request.referer || "/" }
				format.json { ActiveRecord::RecordInvalid.new(@account) }
			end
		end
  end

  # def edit_phone
  #   raise '没有权限' if params[:id].to_i != @current_user.id
  # 	@account = Core::Account.find(params[:id])
  # end

  def validate_account
    if params[:login].blank?
      render json: { code: 401, error: "请输入账户"}
      return
    end

    if params[:genre] == "reset"
      unless Core::Account.active.search_by_params(params.permit(:login))
        render json: { code: 401, error: "该账号未注册"}
        return
      end
    else
      if Core::Account.active.search_by_params(params.permit(:login))
        render json: { code: 401, error: "该账号已注册"}
        return
      end
    end
    render json: { success: true }
  end

  def update_phone
    @account = Core::Account.find(params[:id])
    phone = params[:phone].to_s
    password = params[:password].to_s
    raise '没有权限' if @account.id != @current_user.id
    raise "手机号输入错误" unless phone.is_mobile?
    raise '手机验证码错误' unless @account.bunding_verify_code(phone, params[:captcha])

    success = if @account.crypted_password.blank?
      # 第三方登录绑定手机号
      raise "手机号已绑定" if Core::Account.active.find_by phone: phone
      raise '请输入密码' if password.blank?
      @account.update_attributes(phone: phone, password: password)

    elsif @account.email.present? && @account.crypted_password && @account.phone.blank?
        # 邮箱注册账户绑定手机号
      raise "手机号已绑定" if Core::Account.active.find_by phone: phone
      if password.present?
        @account.update_attributes(phone: phone, password: password)
      else
        @account.update_attributes(phone: phone)
      end
    else
      raise '请输入密码' if password.blank?
      @account.update_attributes(password: password)
    end

		if success
      CoreLogger.info(controller: 'Home::Accounts', action: 'update_phone', phone: params[:phone],user_id: @account.try(:id), current_user: @current_user.try(:id))
			respond_to do |format|
				format.html
				format.json { render json: { success: true } }
			end
		else
			respond_to do |format|
				format.html
				format.json { raise "操作失败" }
			end
		end
  end

  def reset
    @account = Core::Account.search_by_params((params[:account]||{}).slice(:login, :email, :phone))
    unless params[:account][:login].present?
      flash[:notice] = '账号不能为空'
      redirect_to find_accounts_path
      return
    end
    unless verify_rucaptcha?(params[:_rucaptcha])
      flash[:notice] = '验证码输入错误'
      redirect_to find_accounts_path(login: params[:account][:login])
      return
    end
    if @account
      is_email = params[:account][:email] || params[:account][:login] && params[:account][:login].include?('@')
      if is_email
        Core::MobileCode.send_email_code(@account.email, 'reset', 60)
      else
        Core::MobileCode.send_code(@account.phone, 'reset', 'sms', 10)
      end

			respond_to do |format|
        flash[:notice] = "验证码已发到该#{is_email ? '邮箱' : '手机'}"
        CoreLogger.info(controller: 'Home::Accounts', action: 'reset',user_id: @account.try(:id), current_user: @current_user.try(:id))
				format.html { redirect_to new_password_account_path(@account) }
				format.js { render text: "" }
			end
		else
			respond_to do |format|
        flash[:notice] = "没有找到该账户"
				format.html { redirect_to action: 'find' }
				format.js { raise }
			end
		end
	end

  def forget_password
    @account = Core::Account.search_by_params(params.require(:account).permit(:login, :email, :phone))
    raise "没有该账号" unless @account
    password = params[:account] && params[:account][:password]
    @account.password = @account.password_confirmation = password

		if @account.save
      CoreLogger.info(controller: 'Home::Accounts', action: 'forget_password',user_id: @account.try(:id), current_user: @current_user.try(:id))
			respond_to do |format|
				format.html { redirect_to request.referer || "/" }
				format.js
			end
		else
			respond_to do |format|
				format.html { redirect_to request.referer || "/" }
				format.js { ActiveRecord::RecordInvalid.new(@account) }
			end
		end
  end


	def activate
		logout_keeping_session!
		@account = Core::Account.find_by(id: params[:id])

		success =	if params[:activation_code] == @account.activation_code
			if first_active = !@account.activated_at
				@account.activate!
				#@account.send_active_success_email
			end
			true
		else
			false
		end

		if success
			self.current_account = @account

			respond_to do |format|
				format.html { redirect_to '/' }
				format.json
			end
		else
			respond_to do |format|
				format.json { raise '激活失败' }
			end
		end
	end

	private

	def authorized?
		super
		return false if @current_account.nil? && %w[edit_phone update_phone edit_password].include?(params[:action])
		true
	end

	# 邮箱已经被验证
	def emailerrorsuccess
	end
	# 激活邮箱提示页
	def emaila
	end
	# 邮箱激活成功
	def emailsuccess
	end
	# 邮箱验证过期
	def emailerror
	end
end
