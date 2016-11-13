##
# = 核心 用户 表
#
# == Fields
#
# email :: 邮箱
# phone :: 电话
# crypted_password :: 确认密码
# salt :: 缩写
# remember_token :: 验证码
# remember_token_expires_at :: 验证码过期时间
# ip_address :: ip地址
# client :: 客户端
# last_login_on :: 最后登录时间
# token :: 概要
# activation_code :: 未用
# activated_at :: 未用
# active? :: 有效？
#
# == Indexes
#
# name
#
class Core::Account < ActiveRecord::Base
	include Redis::Objects

	counter :v3_count, default: 0
	belongs_to :user, foreign_key: 'id'
	has_many :connections, -> { where active: true }, class_name: "Core::Connection"

	attr_accessor :password
	validates :phone, uniqueness: {:message => '该手机号已存在', if: :active?, scope: :active}, length: { is: 11 }, format: { with: /\A1[3|4|5|7|8]\d{9}\z/ }, allow_blank: true
	validates :email, uniqueness: {:message => '该邮箱已存在', if: :active?, scope: :active}, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true
	validates :password, length: { in: 6..128 }, if: :password_required?

	# CLIENTS = %w[manage html5 osx windows linux flash iphone ipad android phone_web ipad_web wechat]
  #
	# validates_inclusion_of :client, in: CLIENTS, allow_blank: true

	attr_accessor :password_confirmation

	before_save :encrypt_password

	scope :active, -> { where(active: true) }
	scope :promoted, -> { where("activated_at IS NOT NULL") }

	def encrypt(password)
		# self.password_digest(password, salt)
		::BCrypt::Password.create(password, cost: 10)
	end

	def authenticated?(password)
		# crypted_password == encrypt(password)
		crypted_password == BCrypt::Engine.hash_secret(password, salt)
	end

	def encrypt_password
		return if (password || "").size == 0
		# self.salt ||= self.make_token
		bcrypt = BCrypt::Password.create(password, cost: 10)
		self.salt = bcrypt.salt.to_s
		self.crypted_password = bcrypt.to_s
    self.login_salt = make_new_login_salt
	end

	def remember_token?(auth_token)
		self.remember_token && self.remember_token == auth_token && self.remember_token_expires_at && Time.now - self.remember_token_expires_at
		#self.remember_token && self.remember_token == auth_token && self.remember_token_expires_at(没勾上”以后自动登陆的话“，这个字段在logout_keeping_session! -> forget_me里已经被置为nil了） && Time.now - self.remember_token_expires_at
	end

	def self.authenticate(login, password)
		return nil if login.blank? || password.blank?
		u = login.include?('@') ? find_by_email(login) : find_by_phone(login)
		u && u.authenticated?(password) ? u : nil
	end

	def secure_digest(*args)
		Digest::SHA1.hexdigest(args.flatten.join('--'))
	end

	def make_token
		secure_digest(Time.now, (1..10).map{ rand.to_s })
	end

  def reset_login_salt
    token = SecureRandom.hex(10)
    self.update!(login_salt: token) if self.id.present?
    token
  end

  def make_new_login_salt
    SecureRandom.hex(10)
  end

	def password_digest(password, salt)
		digest = REST_AUTH_SITE_KEY

		REST_AUTH_DIGEST_STRETCHES.times do
			digest = secure_digest(digest, salt, password, REST_AUTH_SITE_KEY)
		end

		digest
	end

	def remember_me
		remember_me_for 60.days
	end

	def remember_me_for(time)
		remember_me_until time.from_now
	end

	def remember_me_until(time) #:nodoc: all
		return if self.remember_token_expires_at && self.remember_token_expires_at > Time.now
		self.remember_token_expires_at = time
		self.remember_token = "%06d" % rand(1000000)
		save(false)
	end

	def send_active_sms
		return unless self.phone && self.phone_activation_code
		Core::Sms.create!(:user_id => self.id, :phone => self.phone, :content => "[激活手机账号] 您的激活码是#{self.phone_activation_code}。请在30分钟内输入激活码进行手机账号激活。", :active => false).send_by!(nil, 'high')
	end

	def forget_me #:nodoc: all
		self.remember_token_expires_at = nil
		self.remember_token = nil
		save(false)
	end

	def reset_code
		secure_digest(self.crypted_password).slice(0, 6)
	end

	def self.search_by_params(params = {})
		params.to_h.symbolize_keys!
		id = params[:id] && (params[:id].to_i > 0) && params[:id].to_i
		email = params[:email]
		phone = params[:phone]
		(login = params[:login]) && (login.include?('@') ? (email = login) : (phone = login))
		account = email && self.active.find_by(email: email) || phone && self.active.find_by(phone: phone) || id && self.active.find(id)
		account && account.active? ? account : nil
	end

	def has_password
		!self.crypted_password.nil?
	end

	def has_email
		!self.email.nil? && self.email
	end

	def has_phone
		!self.phone.nil?
	end

	def password_required?
		#crypted_password.blank? || !password.blank?
		!password.blank?
	end

  def reset_code_valid?(code)
    Core::MobileCode.verify_code?(phone, code) || Core::MobileCode.verify_code?(email, code, 'email')
	end

	def make_phone_verify_code(code)
		Core::MobileCode.verify_code?(phone, code) || Core::MobileCode.verify_code?(email, code, 'email')
  end

  def bunding_verify_code(phone, code)
		Core::MobileCode.verify_code?(phone, code)
  end

	def self.need_captcha?(client_ip) #:nodoc: all
		where("ip_address = ? and created_at > ?", client_ip, (Time.now - 24.hour)).size >= 3
	end

  def make_reset_code
    return true unless email
    self.remember_token = "%06d" % rand(1000000)
    self.remember_token_expires_at = Time.new + 3.hour
    self.save
  end

	def make_activation_code
		return true unless email
		self.activation_code = "%06d" % rand(1000000)
		# self.phone_activation_code_expired_at = Time.new + 1.day
	end

	def activate!
		@activated = true
		self.activated_at ||= Time.now
		self.activation_code = nil
		self.remember_token_expires_at = nil
		save(validate: false)
	end

	def send_active_email
		return unless self.email && self.activation_code
		if self.activated_at
      SendEmailWorker.perform_async(id, "恭喜您成功注册Owhat账户", 'signup')
		else
      SendEmailWorker.perform_async(id, "Owhat邮件激活", 'active')
		end
	end
end
