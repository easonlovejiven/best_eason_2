module SendMessage
  class Yunpian

    include Singleton

    def initialize
      @options = SMS_CONFIG['yunpian']
    end

    def api(method, type = 'sms', params = {})
			begin
        url = (type == 'voice' ? @options['voice_url'] : @options['sms_url']) + method
				res = Timeout::timeout(20){ HTTParty.post(url, body: params) }
        res = eval(res.body)
        logger.info({params: params, channel: 'yunpian', type: type, result: res})
        res
      rescue Exception => e
				return {code: 601, error: '网络超时'}
      end
		end

    def send_single_sms(mobile, text)
      return unless mobile.present? && mobile.is_mobile? && text.present?
      response = api('single_send.json', 'sms', {apikey: @options['apikey'], mobile: mobile, text: text})
    end

    def send_voice(mobile, code)
      return unless mobile.present? && code.present?
      response = api('send.json', 'voice', {apikey: @options['apikey'], mobile: mobile, code: code})
    end

    def logger
    	Logger.new(Rails.root.join("log/sms.log"))
  	end

  end
end
