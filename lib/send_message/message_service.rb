module SendMessage
  class MessageService

    def self.send_sms(phone, text, template = {})
      if text.present?
        #yunpian
        res = SendMessage::Yunpian.instance.send_single_sms(phone, text)
        return {ret: true} if res[:code] == 0
      end
      #leancloud
      return {ret: false, error: '短信模版错误'} unless template[:name].present? && template[:data].present?
      res = SendMessage::Leancloud.instance.send_template_sms(phone, template[:name], template[:data])
      return {ret: true} if res.blank?
      {ret: false, error: res[:error]}
    end

    def self.send_voice_code(phone, code)
      res = SendMessage::Yunpian.instance.send_voice(phone, code)
      return {ret: true} if res[:sid].present?
      {ret: false, error: res[:msg]}
    end

  end
end
