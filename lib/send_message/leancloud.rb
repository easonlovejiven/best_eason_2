module SendMessage
  class Leancloud

    include Singleton

    def initialize
      @options = SMS_CONFIG['leancloud']
    end

    def api(method, params = {})
			headers = { "Content-Type" => "application/json", "X-AVOSCloud-Application-Id"  => @options["appid"], "X-AVOSCloud-Application-Key" => @options["appkey"] }
			begin
				res = Timeout::timeout(20){ HTTParty.post(@options['gateway']+ method, body: params.to_json, headers: headers) }
        res = eval(res.body)
        logger.info({params: params, channel: 'leancloud', type: 'text', result: res})
        res
      rescue Exception => e
				return {code: 601, error: '网络超时'}
      end
		end

    def send_template_sms(phone, template, data = {})
			return unless phone.present? && phone.is_mobile? && template.present?
      response = api('requestSmsCode', { mobilePhoneNumber: phone, template: template}.merge(data))
		end

    def logger
    	Logger.new(Rails.root.join("log/sms.log"))
  	end

  end
end
