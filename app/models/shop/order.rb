##
# = 商品类 总订单（商品活动类） 表
#
# == Fields
#
# order_no :: 订单号
# total_fee :: 总价格（包含运费）
# status :: 订单状态 1待付款 2已付款 -1 已删除 -2 已取消
# platform :: 平台 Android iOS web
# address_id :: 地址
# paid_at :: 支付时间
# user_id :: 购买用户id
# is_deleted :: 未用
# pay_type :: {bank_pay: "网上银行", alipay: "支付宝", wx_pay: "微信", free: '免费' }
# freight_fee :: 运费
# expired_at :: 订单过期时间
# question_memo :: 未用
# updated_paid_at :: 更新订单状态的时间（当支付宝、微信出现异常时 需技术手动修改订单状态，这是修改状态的时间）
# active? :: 有效？
#
# == Indexes
#
# name
#
class Shop::Order < ActiveRecord::Base
  include ActAsActivable

  has_many :order_items, class_name: "Shop::OrderItem", dependent: :destroy
  belongs_to :core_address, class_name: "Core::Address", foreign_key: :address_id
  belongs_to :user, class_name: "Core::User"
  belongs_to :address, class_name: "Core::Address"

  scope :time_out, ->{where(status: 1).where("expired_at < ?", Time.now)}

  validates :order_no, uniqueness: true

  PAY_TYPES = {bank_pay: "网上银行", alipay: "支付宝", wx_pay: "微信", free: '免费' }.freeze
  enum pay_type: PAY_TYPES.keys
  enum status: {pending: 1, paid: 2, checked: 3, deleted: -1, canceled: -2 } #支付状态

  def get_freight_fee_hash
    @products_hash = {}
    self.order_items.each do |item|
      ticket_type = item.ticket_type
      task_id = "#{ticket_type.task_id}"+"#{ticket_type.task_type}"
      if @products_hash.has_key?(task_id)
        @products_hash.update({ task_id => @products_hash[task_id].merge!({ ticket_type.id => item.quantity }) })
      else
        @products_hash.merge!({
          task_id => { ticket_type.id => item.quantity }
        })
      end
    end
    return @products_hash
  end

  def self.web_order_create shop_orders, address_id, freight_fee, sum_fee, current_user
    @products_hash, total_fee = {}, 0
    all_ticket_types = []
    shop_orders.each do |order|
      ticket_type = Shop::TicketType.find_by(id: order[:ticket_type_id])
      return [false,  "价格信息发生变化，请重新购买"] unless ticket_type.present?
      array_status = ticket_type.created_order_options(order, order[:quantity], current_user)
      return [false, array_status[1]] if !array_status[0] #判断是否能够购买
      total_fee += ticket_type.fee.to_f.round(2)*order[:quantity].to_i
      task_id = "#{ticket_type.task_id}"+"#{ticket_type.task_type}"
      if @products_hash.has_key?(task_id)
        @products_hash.update({ task_id => @products_hash[task_id].merge!({ ticket_type.id => order[:quantity].to_i }) })
      else
        @products_hash.merge!({
          task_id => { ticket_type.id => order[:quantity].to_i }
        })
      end
      Shop::Cart.delete_cart(current_user, ticket_type.task.user.id, order)
      all_ticket_types << [ticket_type, order[:quantity]]
    end
    get_freight_fee = Shop::OrderItem.calculate_freight_fee(address_id.to_i, @products_hash)
    return [false,  "该地址不支持购买"] if get_freight_fee[0] == '该地址不支持购买'
    return [false, "邮费价格结算错误，请重新结算(可能您的地址编辑出现问题， 请将地址必填项填好。)"] if get_freight_fee[0] == false || freight_fee.to_f.round(2) != get_freight_fee[1].values.sum
    return [false, "不要试图更改价格！！！"] if (total_fee.to_f.round(2) + freight_fee.to_f.round(2)).to_f.round(2) > sum_fee.to_f.round(2)
    #参与人数增加
    all_ticket_types.map{|t,count| t.participator.incr(count)}
    return [true, "可以创建"]
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

end
