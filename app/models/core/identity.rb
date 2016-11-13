class Core::Identity < ActiveRecord::Base
  scope :active, -> { where(active: true) }

  belongs_to :user

  enum status: { "待审核" => 0, "通过" => 1, "拒绝" => -1 }

  after_create :send_notify_mail
  def send_notify_mail
    SendEmailWorker.perform_async(self.user_id, "申请账号认证", 'identity_apply')
  end

  def org_pic_url
    org_pic.present? ? "http://#{Settings.qiniu["host"]}/#{org_pic}" : 'http://qimage.owhat.cn/o_meio-mei.png'
  end

  def id_pic_url
    id_pic.present? ? "http://#{Settings.qiniu["host"]}/#{id_pic}" : 'http://qimage.owhat.cn/o_meio-mei.png'
  end

  def id_pic2_url
    id_pic2.present? ? "http://#{Settings.qiniu["host"]}/#{id_pic2}" : 'http://qimage.owhat.cn/o_meio-mei.png'
  end
end
