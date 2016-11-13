class ApplicationController < ActionController::Base
  around_filter :respond_to_json
	before_filter :login_filter
  before_filter :get_hot_record
  # before_filter :great_firewall

	private

  def get_hot_record
    record = Rails.cache.fetch("record", expires_in: Time.now.end_of_day - Time.now + 4.hours) do
      Core::HotRecord.order(position: :desc).first
    end
    @hot_records = Rails.cache.fetch("hot_records", expires_in: Time.now.end_of_day - Time.now + 4.hours) do
      Core::HotRecord.order(position: :desc).limit(3).map(&:name)
    end
    if record.present?
      @search_key = record.name
    else
      @search_key = "请输入关键字"
    end
  end

  def login_filter
    if current_account && current_user
      if session[:user_login_on] != Time.now.to_date
        @current_user.login_today('web', {
          ip_address: request.remote_ip,
          client: 'web',
          user_agent: request.user_agent
        })
        session[:user_login_on] = Time.now.to_date
        # session[:user_name] = current_user.name
        # session[:user_pic] = current_user.pic
      end
      @current_account.try(:reset_login_salt) if @current_account.try(:login_salt).blank?
    else
      session[:account_id] = SecureRandom.hex(16)
    end
    logout_keeping_session! if @current_account.present? && session[:login_salt] != @current_account.login_salt
    not_authorized if !authorized?
  end

	def not_authorized
		if @current_user
      respond_to do |format|
        format.html { raise ActiveResource::ForbiddenAccess.new(response) }
        format.json   { raise ActiveResource::ForbiddenAccess.new(response) }
      end
    else
     	respond_to do |format|
	      format.html { redirect_to new_session_path(:redirect => request.fullpath) }
       	format.json { raise ActiveResource::UnauthorizedAccess.new(response) }
     	end
    end
  end

  def respond_to_json
    return yield unless (request.format && request.format.to_sym.to_s) == 'json'
    begin
      yield
    rescue => e
      unless e.is_a?(ActionView::MissingTemplate)
        data = { error: e.message }
        logger.warn %[#{e.class.to_s}: #{e.message}\n#{e.backtrace.map{|s| "\tfrom #{s}\n" }.join}]
      end
      render json: data || {}
    end
  end

  def great_firewall
    params = gfw(request.params) if request.post? || request.put?
  end

  def gfw(h)
    @keyword_regexp ||= begin
      return h if ( cks = Rails.cache.fetch("core-keywords_list",:raw=>true) { Core::Keyword.active.map(&:name).map{|n|Regexp.escape(n)}.join('|') } ).blank?
      cks
    end

    if h.is_a?(Hash)
      h.each_pair { |k, v| h[k] = [:controller, :action, :id].include?(k) ? v : gfw(v) }
    elsif h.is_a?(Array)
      h = h.map { |v| gfw(v) }
    elsif h.is_a?(String)
      h = h.gsub(@keyword_regexp, '?')
    else
    end

    h
  end


  def logged_in?
    @current_account
  end

  def current_account
    # @current_account ||= (login_from_session || login_from_basic_auth || login_from_cookie) unless @current_account == false
    @current_account ||= login_from_session || login_from_basic_auth
  end

  def current_account=(new_account)
    session[:user_id] = new_account ? new_account.id : nil
    session[:user_expired_at] = 1.days.from_now
    session[:login_salt] = new_account ? new_account.login_salt : nil
    @current_account = new_account || false
  end

  def login_from_session
    # Rails.logger.info { "#{session.inspect}" }
    current_account = Core::Account.find_by_id(session[:user_id]) if session[:user_id] && session[:user_expired_at] && Time.now < session[:user_expired_at]
  end

  def login_from_basic_auth
    authenticate_with_http_basic do |email, password|
      current_account = Core::Account.authenticate(email, password)
    end
  end

  def login_from_cookie
    id, auth_token = (params[:auth_token] || cookies[:auth_token]).split('-') if params[:auth_token] || cookies[:auth_token]
    account = id && auth_token && Core::Account.find_by_id(id)
    if account && account.remember_token?(auth_token)
      current_account = account
      handle_remember_cookie! true
      current_account
    end
  end

  def logout_keeping_session!
    # @current_account.forget_me if @current_account.is_a? Core::Account
    @current_account = nil
    @current_user = nil
    # kill_remember_cookie!
    session[:user_id] = nil
    session[:user_login_on] = nil
  end

  def logout_killing_session!
    logout_keeping_session!
    reset_session
  end

  def handle_remember_cookie!(new_cookie_flag)
    return unless @current_account
    @current_account.remember_me_until(new_cookie_flag ? 60.days.from_now : nil)
    send_remember_cookie!
  end

  def kill_remember_cookie!
    cookies.delete :auth_token
  end

  def send_remember_cookie!
    cookies[:auth_token] = {
      :domain => ".owhat.cn",
      :value => "#{@current_account.id}-#{@current_account.remember_token}",
      :expires => @current_account.remember_token_expires_at
    }
  end

  def current_user
    @current_user ||= (@current_account.user if @current_account)
  end

  def current_user= new_user
    @current_user = new_user
  end

  def authorized?
    true
  end

  def database_transaction
		begin
			ActiveRecord::Base.transaction do
				yield
			end
			true
		rescue => e
			logger.error %[#{e.class.to_s} (#{e.message}):\n\n #{e.backtrace.join("\n")}\n\n]
			false
		end
	end
end
