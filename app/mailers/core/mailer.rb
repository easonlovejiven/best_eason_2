class Core::Mailer < ApplicationMailer
	default from: %["Owhat" <#{::MAILER_CONFIG['from']['default']}>], content_type: "text/html"

  def standard_mail(options = {})
		options[:date] ||= options[:sent_on]
		options[:to] ||= options[:recipients]
		# [options[:attachments] || options[:attachment]].flatten.compact.each { |attachment| attachments[attachment[:filename]] = attachment }
		mail(options) do |format|
			format.html do
				if options[:template]
					(options[:body] || {}).each { |key, value| instance_variable_set("@#{key}", value) }
					render file: "core/mailer/#{options[:template]}.html.erb", layout: options[:layout]
				else
					render text: options[:body]
				end
			end
		end
	end

	def self.mail(options = {})
		return if (options[:to] || options[:recipients]).blank?
		self.standard_mail(options).deliver
	end

	def self.attachment_mail(options = {})
    return if (options[:to] || options[:recipients]).blank?
    self.send_attachments_mail(options).deliver
  end

  # 报表统计
  def send_attachments_mail(options = {})
    attachments["#{options[:subject]}.xlsx"] = {
      :mime_type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      :content => options[:body].to_stream.read 
    }
    mail(options) do |format|
      format.html do
        render text: options[:filename]
      end
    end
  end

	def self.send_code_mail(options = {})
		response = RestClient.post "http://api.sendcloud.net/apiv2/mail/send",
    :apiUser => MAILER_CONFIG['send_cloud']['apiUser'], # 使用api_user和api_key进行验证
    :apiKey => MAILER_CONFIG['send_cloud']['apiKey'],
    :from => "noreply@owhat.cn", # 发信人，用正确邮件地址替代
    :fromName => "O妹",
    :to => options["email"], # 收件人地址，用正确邮件地址替代，多个地址用';'分隔
    :subject => options["subject"],
    :html => options["content"]
    response
	end

end
