##
# = 商品类 子订单（商品活动类） 表
#
# == Fields
#
# order_no :: 订单号
# owhat_product_id :: 对应商品活动id
# owhat_product_type :: 对应是商品还是活动
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
# expired_at :: 订单过期时间
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
class Shop::OrderItem < ActiveRecord::Base
  include ActAsActivable#多个model重用方法module
  include Redis::Objects

  lock :shop_ticket_type_id

  before_create :set_default
  after_update :update_task_state

  belongs_to :user, class_name: "Core::User"
  belongs_to :core_address, class_name: "Core::Address", foreign_key: :address_id
  belongs_to :order, class_name: "Shop::Order"
  belongs_to :ticket_type, class_name: "Shop::TicketType", foreign_key: :shop_ticket_type_id
  belongs_to :owhat_product, polymorphic: true #多态关联商品 活动 应援
  has_many :ext_info_values, class_name: "Shop::ExtInfoValue", foreign_key: :ext_info_id
  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"

  validates :order_no, uniqueness: true

  PAY_TYPES = {bank_pay: "网上银行", alipay: "支付宝", wx_pay: "微信", free: '免费' }.freeze
  enum pay_type: PAY_TYPES.keys
  enum status: {pending: 1, paid: 2, checked: 3, deleted: -1, canceled: -2 } #支付状态

  scope :by_id_and_type, ->(id, type){where(owhat_product_id: id, owhat_product_type: type)}
  scope :by_id, ->(id){where(owhat_product_id: id)}
  scope :by_type, ->(type){where(owhat_product_type: type)}
  scope :time_out, ->{where(status: 1).where("expired_at < ?", Time.now)}

  cattr_accessor :manage_fields do
    %w[ id order_no owhat_product_id owhat_product_type user_id code status pay_type quantity payment paid_at pay_at canceled_at qr_code qr_code_fingerprint is_deleted paid_sms_sent_at qr_code_created_at qr_path_cache alipay_payment_at checked_at address_id owner_id order_id shop_ticket_type_id active created_at updated_at platform memo user_name phone address freight_fee is_income expired_at basic_order_no split_memo question_memo creator_id updater_id]
  end

  def set_default
    self.order_no = UUID.generate(:compact)
  end

  def update_task_state
    #改变是否用户完成了该任务
    if self.status == 'paid'
      if self.owhat_product.shop_task.task_state["#{owhat_product_type}:#{user_id}"] == 0
        self.owhat_product.shop_task.task_state["#{owhat_product_type}:#{user_id}"] = 1
      else
        self.owhat_product.shop_task.task_state["#{owhat_product_type}:#{user_id}"] += 1
      end
    end
  end

  def self.calculate_freight_fee address_id, products_hash = {}, get_freight_fee=false
    province_name = Core::Address.find_by(id: address_id).try(:province_name)
    ticket_type_hash = {}
    products_hash.each do |key, ticket_types|
      ticket_type = Shop::TicketType.find_by(id: ticket_types.first[0])
      if ticket_type.task.try(:freight_template_id).blank? || province_name.blank?
        ticket_types.each do |t, q|
          ticket_type_hash.merge!({ t => 0 })
        end
        next
      end
      freight = Shop::Freight.active.where(freight_template_id: ticket_type.task.try(:freight_template_id), destination: province_name).first || Shop::Freight.where(freight_template_id: ticket_type.task.try(:freight_template_id), destination: '其它').first
      sum_quantity = ticket_types.values.sum
      if freight
        if sum_quantity > freight.frist_item
          if (sum_quantity - freight.frist_item) / freight.reforwarding_item == 0
            freight_fee = freight.first_fee + freight.reforwarding_fee
          else
            if (sum_quantity - freight.frist_item) % freight.reforwarding_item == 0
              freight_fee = freight.first_fee + freight.reforwarding_fee * ( (sum_quantity - freight.frist_item) / freight.reforwarding_item )
            else
              freight_fee = freight.first_fee + freight.reforwarding_fee * ( (sum_quantity - freight.frist_item) / freight.reforwarding_item ) + freight.reforwarding_fee
            end
          end
        else
          freight_fee = freight.first_fee
        end
      else
        if get_freight_fee
          freight_fee = 0
        else
          return ['该地址不支持购买', {ticket_type.id => 0}]
        end
      end
      ticket_types.each_with_index do |(t, q), index|
        unless index == 0
          ticket_type_hash.merge!({ t => 0 })
        else
          ticket_type_hash.merge!({ t => freight_fee.to_f.round(2) })
        end
      end
    end
    if province_name.blank?
      [false, ticket_type_hash]
    else
      [true, ticket_type_hash]
    end
  end

end
