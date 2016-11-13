##
# = 商品类 应援订单 表
#
# == Fields
#
# order_no :: 订单号
# shop_funding_id :: 对应应援id
# user_id :: 用户id
# status :: 支付状态
# pay_type :: {bank_pay: "网上银行", alipay: "支付宝", wx_pay: "微信", free: '免费' }
# quantity :: 购买数量
# payment :: 总价格
# paid_at :: 支付时间
# address_id :: 地址id 对应 core_addresses表
# owner_id :: 发布该商品和活动人的用户id
# order_id :: 未用
# shop_ticket_type_id :: shop_ticket_types商品价格id
# memo :: 附加信息
# platform :: 来源平台 android ios web
# user_name :: 用户购买地址的用户名
# phone :: 用户购买地址的电话
# address :: 用户购买地址的用户名
# freight_fee :: 运费
# question_memo :: 附加信息
# basic_order_no :: 总订单号
# split_memo :: 附加信息
# updated_paid_at :: 更新订单状态的时间（当支付宝、微信出现异常时 需技术手动修改订单状态，这是修改状态的时间）
# question_memo ::
# active? :: 有效？
#
# == Indexes
#
# name
#
class Shop::FundingOrder < ActiveRecord::Base
  include ActAsActivable#多个model重用方法module

  after_update :update_task_state

  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  # belongs_to :order, class_name: "Shop::Order"
  belongs_to :ticket_type, class_name: "Shop::TicketType", foreign_key: :shop_ticket_type_id
  belongs_to :owhat_product, class_name: "Shop::Funding", foreign_key: :shop_funding_id
  belongs_to :core_address, class_name: "Core::Address", foreign_key: :address_id
  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"

  validates :order_no, uniqueness: true

  PAY_TYPES = {bank_pay: "网上银行", alipay: "支付宝", wx_pay: "微信", free: '免费' }.freeze
  enum pay_type: PAY_TYPES.keys
  enum status: {pending: 1, paid: 2, checked: 3, deleted: -1, canceled: -2 } #支付状态
  cattr_accessor :manage_fields do
    %w[ id order_no shop_funding_id user_id status pay_type quantity payment paid_at pay_at canceled_at checked_at address_id owner_id shop_ticket_type_id active created_at updated_at platform memo user_name phone shop_funding_type is_income address split_memo question_memo creator_id updater_id]
  end
  def update_task_state
    #改变是否用户完成了该任务
    if self.status == 'paid'
      if self.owhat_product.shop_task.task_state["#{shop_funding_type}:#{user_id}"] == 0
        self.owhat_product.shop_task.task_state["#{shop_funding_type}:#{user_id}"] = 1
      else
        self.owhat_product.shop_task.task_state["#{shop_funding_type}:#{user_id}"] += 1
      end
    end
  end

  def can_order_pay_and_cancel?
    return false if status != 'pending'
    return false if (Shop::OrderHelper.get_weixin_paid_info('web', self) || {})[:is_paid]
    return false if (Shop::OrderHelper.get_weixin_paid_info('app', self) || {})[:is_paid]
    return false if (Shop::OrderHelper.get_alipay_paid_info(self) || {})[:is_paid]
    true
  end

  def cancel_alipay_weixin_order
    Shop::OrderHelper.cancel_alipay_paid(self)
    Shop::OrderHelper.cancel_weixin_paid('web', self)
    Shop::OrderHelper.cancel_weixin_paid('app', self)
  end

  def share_info
    funding = self.owhat_product
    creator = funding.user
    {
      content: "我在 @Owhat 赞助了 #{'@'+creator.name} 发起的应援活动 #{funding.title}， 我应援了#{payment}元钱，已经有#{funding.shop_task.participator}个人来参加了，应援完成了#{(funding.try(:funding_progres) || 0).to_s}%，快来一起支持O，让这个独一无二的应援早日完成！ #{Rails.application.routes.url_helpers.shop_funding_url(funding)}",
      title: "#{funding.title}",
      share_url: "#{Rails.application.routes.url_helpers.shop_funding_url(funding)}",
      pic: funding.cover_pic,
      funding_progres: funding.try(:funding_progres) || 0
    }
  end

  def weibo_auto_share
    user = self.user
    share_status = user.weibo_auto_share_info
    if share_status[:auto_share_status] == 'yes' && share_status[:weibo_token_active] == true
      res = HTTPClient.post('https://upload.api.weibo.com/2/statuses/update.json', {
        access_token: share_status[:token],
        uid: share_status[:identifier],
        status: share_info[:content]
      })
      p "----------------> 分享应援user_id: #{user.id}; order_id: #{self.id}; res: #{res.try(:body)}"
      true
    else
      false
    end
  end
end
