class Core::Sms < ActiveRecord::Base
	table_name = 'core_smss'

	def send_by!(editor = nil, channel = nil) #:nodoc: all
		raise "already sent before" if self.success?
		self.class.send_sms(phone, content, channel)
		self.update_attributes!(success: true, editor_id: editor && editor.id, send_at: Time.now)
		self
	end


	class << self
		def api(method, params = {}) #:nodoc: all
			options = SMS_CONFIG['leancloud']
			headers = { "Content-Type" => "application/json", "X-AVOSCloud-Application-Id"  => options["appid"], "X-AVOSCloud-Application-Key" => options["appkey"] }
			begin
				res = Timeout::timeout(20){ HTTParty.post(options['gateway']+method, body: params.to_json, headers: headers) }
        eval(res.body)
      rescue Exception => e
				return {code: 601, error: '网络超时'}
      end
		end

		def send_code(phone, type='sms')
			raise '手机号不正确' unless phone.present? && phone.is_mobile?
			# Core::Registration.create()
			response = api('requestSmsCode', {'mobilePhoneNumber' => phone, 'smsType' => type || 'sms' })
		end

		def verify_code?(phone, code)
			response = api("verifySmsCode/#{code}", { 'mobilePhoneNumber' => phone })
		end

		def send_sms(phone, content, template = nil) #:nodoc: all
			raise 'invalid sms parameters' unless !content.blank? && !phone.blank? && phone.to_a.map{|p| p.to_s =~ /1\d{10}/ }.inject(&:&)
      response = api('requestSmsCode', { mobilePhoneNumber: phone, template: template || 'default', content: content })
		end

		def logger
    	Logger.new(Rails.root.join("log/sms.log"))
  	end
	end
end
