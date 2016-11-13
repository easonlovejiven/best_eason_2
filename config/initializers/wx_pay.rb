setting = Rails.application.secrets.weixin.try(:[], "payment") || {}
WxPay.appid = setting["appid"]
WxPay.key = setting["key"]
WxPay.mch_id = setting["mch_id"]
