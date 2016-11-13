class SendEmailWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'email', retry: true, backtrace: true

  def perform(user_id, subject, template, data = {})
    case template
    when "send_code"
      ret = Core::Mailer.send_code_mail(data.merge("subject" => subject))
      Logger.new(Rails.root.join("log/sms.log")).info({data: data, channel: 'email', result: ret})
    when "identity_apply"
      user = Core::User.find_by(id: user_id)
      return p '#{Time.now}————————>error---------------->没有该账户' unless user
      Core::Mailer.mail(
        recipients: MAILER_CONFIG['recipient']['identity_apply'],
        subject: "用户【#{user.name}】申请账号认证",
        body: "用户【#{user.name}】ID【#{user.id}】刚刚申请认证，快来审核O~",
        from: %["Owhat!" <#{MAILER_CONFIG['from']['activation']}>]
      )
    else
      account = Core::Account.find_by(id: user_id)
      return p '#{Time.now}————————>error---------------->没有该账户' unless account
      Core::Mailer.mail(
        recipients: account.email,
        subject: subject,
        template: template,
        body: { user: account.user },
        from: %["Owhat!" <#{MAILER_CONFIG['from']['activation']}>]
      )
    end
  end

end
