class Home::QrcodeController < Home::ApplicationController

  def index
    @rand = SecureRandom.hex(10)
    @qr_code_img = RQRCode::QRCode.new("#{@rand}", size: 3)
    Redis.current.set "#{@rand}", [Time.now+600, nil, nil].to_json #过期时间， 用户id, category
  end

  def authorized?
    true
  end
end
