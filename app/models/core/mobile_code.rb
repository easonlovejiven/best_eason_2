class Core::MobileCode < ActiveRecord::Base
	table_name = 'core_mobile_codes'
  KIND = {register: "注册", reset: "找回密码"}
  CLIENT = {mobile: "手机", email: "邮箱"}

  def self.send_code(phone, kind, type='sms', expiration = 10)#kind:['register', 'reset']］
    raise '手机号不正确' unless phone.present? && phone.is_mobile?
    if kind == 'register'
      account = Core::Account.active.find_by_phone(phone)
      return {ret: false, error: '账户已存在'} if account.present? && account.active?
    end
		mobile_code = self.where('mobile = ? and created_at > ?', phone, Time.now - 90.seconds).order(id: :desc).first
		return {ret: false, error: "发送信息过快，请稍后重试。"} if mobile_code.present?
		code = rand(100000..999999)
    unless type == 'voice'
      text = "【Owhat应用】您正在使用owhat服务进行短信认证，您的验证码是：#{code}，请在#{expiration}分钟内完成验证。"
      res = SendMessage::MessageService.send_sms(phone, text, {name: 'captcha', data: {captcha: code, expiration: expiration}})
    else
      res = SendMessage::MessageService.send_voice_code(phone, code)
    end
    self.create(mobile: phone, code: code, end_time: Time.now.to_i + expiration.minutes.to_i, kind: kind, client: 'mobile') if res[:ret]
    res
  end

  def self.send_email_code(email, kind, expiration = 10)
    raise '邮箱不正确' unless email.present? && email.is_email?
    if kind == 'register'
      account = Core::Account.active.where(email: email).first
      return {ret: false, error: '账户已存在'} if account.present? && account.active?
    end
    mobile_code = self.where('mobile = ? and created_at > ?', email, Time.now - 90.seconds).order(id: :desc).first
    return {ret: false, error: "发送信息过快，请稍后重试。"} if mobile_code.present?
    code = rand(100000..999999)
    data = {
      email: email,
      content: kind=='register' ?
      "【Owhat】您的邮箱正在申请注册Owhat账号，验证码是：#{code}（#{expiration}分钟内有效）。请勿将验证码泄露给他人。" :
      "【Owhat】您的账号正在申请找回密码，验证码是：#{code}（#{expiration}分钟内有效）。请勿将验证码泄露给他人。"
    }
    SendEmailWorker.perform_async('', kind=='register'? "【Owhat】新账号注册验证" : "【Owhat】找回密码验证", 'send_code', data)
    ret = self.create(mobile: email, code: code, end_time: Time.now.to_i + expiration.minutes.to_i, kind: kind, client: 'email')
    {ret: ret.id.present?, error: ret.id.present? ? '成功' : '失败，请重试'}
  end

  def self.verify_code?(phone, code, client = 'mobile')
    return false unless phone.present?
    mobile_code = self.where("mobile = ?  and code = ? and end_time > ? and client = ? ", phone , code, Time.now.to_i, client).order(id: :desc).first
    mobile_code.update_attributes(verified: true) if mobile_code.present?
    mobile_code.present?
  end

end
