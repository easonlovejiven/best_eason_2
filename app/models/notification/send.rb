class Notification::Send < ActiveRecord::Base
  include ActAsActivable
  include Redis::Objects

  belongs_to :creator, class_name: "Core::User", foreign_key: :creator_id
  belongs_to :updater, class_name: "Core::User", foreign_key: :updater_id
  belongs_to :sendor, class_name: "Core::User", foreign_key: :sendor_id
  has_many :send_statistics

  validates :content, :presence => {:message => "不能为空！"},
            :length => {:minimum => 1, :maximum => 50, :message => "不可超过50个字（含标点），请检查"}
  validates :skip_id, :presence => {:message => "跳转ID不能为空！"}
  validates :skip_channel, :presence => {:message => "跳转频道不能为空！"}
  validates :os, :presence => {:message => "平台不能为空！"}
  validates :skip_id, numericality: { only_integer: false, message: "只能输入数字哦！" }, if: Proc.new { |record| skip_id.present? }

  scope :by_send_date, ->(begin_date, end_date) { where("send_date BETWEEN ? AND ?", begin_date, end_date) }
  scope :by_sended, -> { where("send_status != ? ", 3) }

  cattr_accessor :manage_fields do
    %w[ id content sendor_id object_name send_date push_content os receivor_id creator_id covupdater_id updater_id skip_channel skip_id send_status send_type push_type]
  end

  SKIP_CHANNEL = { 'Shop::Topic' => "任务/话题", 'Shop::Media' => "任务/O妹精选", 
                'Qa::Poster' => '任务/死忠粉', 'Shop::Product' => '任务/Shop/商品', 
                'Shop::Event' => '任务/Shop/活动', 'Shop::Funding' => '任务/应援',
                'Shop::Subject' => '任务/直播', 'Welfare::Letter' => '福利/图片',
                'Welfare::Voice' => '福利/语音', 'Welfare::Product' => '福利/商品',
                'Welfare::Event' => '福利/活动', 'core_star' => '明星主页',
                'core_user' => '个人主页' }
  SEND_STATUS = { 1 => '待发送', 2 => '已发送', 3 => '已撤销' }
  PUSH_TYPE = { 0 => 'Push', 1 => '广播' }

  validate :content_validates
  def content_validates
    errors.add(:content,"包含不支持的特殊字符，请检查") if content.present? && (content =~ /\"|\u{201D}|\u{201C}|\\n/ || content.judge_emoji || content.include?("\n") || content.include?("‘") || content.include?("’"))
  end

  validate :skip_id_validates
  def skip_id_validates
    errors.add(:skip_id, "最长不能超过10位！") if skip_id.to_s.length > 10
  end

  validate :only_three_by_day
  def only_three_by_day
    if send_date.present?
      count = Notification::Send.by_sended.by_send_date(send_date.beginning_of_day, send_date.end_of_day).count
      if count >= 3
        errors.add(:id, "一天之内只能发3条！") if count > 3 || send_date_changed?
      end
    end
  end

  validate :only_one_by_hour
  def only_one_by_hour
    if send_date.present?
      count = Notification::Send.by_sended.by_send_date(send_date.beginning_of_hour, send_date.end_of_hour).count
      if count >= 1
        errors.add(:id, "1小时只能发一条！") if count > 1 || send_date_changed?
      end
    end
  end

  def ios_times
    send_statistics.where(platform: 'iOS').size
  end

  def android_times
    send_statistics.where(platform: 'Android').size
  end

  def send_from_rong
    rc_rand = rand(100000)
    time = Time.now.to_i
    sign = signature({'rc_rand' => rc_rand, 'time' => time})
    base_headers = {"RC-App-Key" => Rails.application.secrets.rongcloud.try(:[], "app_key"),
      "RC-Nonce" => rc_rand.to_s, "RC-Timestamp" => time.to_s, 'RC-Signature' => sign.to_s}
    if push_type == 1
      headers = base_headers.merge("Content-Type" => "Application/x-www-form-urlencoded")
      base_body = {'fromUserId' => sendor_id, 'objectName' => object_name, 'content' => "{\"content\":#{content.to_json},\"extra\":#{skip_channel.to_json},\"taskID\":#{skip_id.to_s.to_json} }", 'pushContent' => content, 'pushData' => "{\"content\":#{content.to_json},\"extra\":#{skip_channel.to_json},\"taskID\":#{skip_id.to_s.to_json},\"sendID\":#{id.to_s.to_json}}"}
      body = (os == 'all' ? base_body : base_body.merge(os: os))
      response = HTTParty.post("https://api.cn.ronghub.com/message/broadcast.json", { body: body, headers: headers })
    else
      headers = base_headers.merge("Content-Type" => "application/json")
      os = (self.os == 'all' ? ["ios","android"] : [self.os])
      body = {platform: os, audience: {is_to_all: true}, "notification"=>{alert: content}}
      response = HTTParty.post("https://api.cn.ronghub.com/push.json", { body: body.to_json, headers: headers })
    end
    if response['code'] == 200
      Logger.new(Rails.root.join("log/sms.log")).info({data: body, channel: 'notification_send', result: response})
      update(send_status: 2)
      p "------------->消息#{id}发送成功~"
    else
      Logger.new(Rails.root.join("log/sms.log")).info({data: body, channel: 'notification_send', result: response})
      p "------------->消息#{id}发送失败~"
    end
  end

  def signature(option = {})
    app_secret = Rails.application.secrets.rongcloud.try(:[], "app_secret")
    rc_rand = option['rc_rand']
    time = option['time']
    sign = "#{app_secret}#{rc_rand}#{time}"
    return Digest::SHA1.hexdigest(sign)
  end

  def count_down
    (send_date.class == DateTime || Time) ? send_date.to_i - DateTime.current.to_i : 0
  end

end
