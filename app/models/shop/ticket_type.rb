class Shop::TicketType < ActiveRecord::Base
  include ActAsActivable #多个model重用方法module
  include Redis::Objects

  counter :participator #参与该活动的购买人数

  validates_presence_of :category
  validates_presence_of :second_category

  validates :category, length: { maximum: 20, too_long: "最多输入20个文字" }
  validates :second_category, length: { maximum: 20, too_long: "最多输入20个文字" }
  validates :original_fee, numericality: {less_than_or_equal_to: 65000, greater_than_or_equal_to: 0, message: "小于65000元"}
  validates :fee, numericality: {less_than_or_equal_to: 65000, greater_than_or_equal_to: 0, message: "小于65000元"}
  validates :each_limit, numericality: { only_integer: true, less_than: 1000000000, greater_than_or_equal_to: 0, message: "最多输入9位数字且数量要大于等于0" }
  validates :ticket_limit, numericality: { only_integer: true, less_than: 1000000000, greater_than_or_equal_to: 0, message: "最多输入9位数字且数量要大于等于0" }

  belongs_to :task, polymorphic: true #任务活动应援多态关联
  belongs_to :price_category, class_name: "Shop::PriceCategory", foreign_key: :category_id

  validate :funding_not_free
  def funding_not_free
    if self.task_type == "Shop::Funding"
      errors.add(:fee, "价格需要大于零O~") unless fee > 0.0
    end
  end

  def created_order_options order, quantity, current_user, can_equal=true, address_id=nil
    quantity = quantity.to_i
    info = order.try(:memo) || order[:info]
    split_memo = order[:split_memo].split("%&*")
    task = self.task
    task.ext_infos.map(&:require).each_with_index do |k, i|
      if k == true
        return [false, "缺少必填的附加信息"]  if split_memo[i].blank?
      end
    end
    return [false, "不要试图更改价格！！！"] if quantity.to_i < 0
    if can_equal
      return [false, "该款商品当前购买人数已达上限，请稍后看看有没有取消订单的人再来吧。"] if self.is_limit && self.participator.value.to_i >= self.ticket_limit
      unless task.class.name == "Shop::Funding"
        return [false, "该款商品当前购买人数已达上限，请稍后看看有没有取消订单的人再来吧。"] if self.is_limit && (Shop::OrderItem.where(shop_ticket_type_id: self.id, status: 1).map(&:quantity).sum+Shop::OrderItem.where(shop_ticket_type_id: self.id, status: 2).map(&:quantity).sum) >= self.ticket_limit
      end
    else
      return [false, "该款商品当前购买人数已达上限，请稍后看看有没有取消订单的人再来吧。"] if self.is_limit && self.participator.value.to_i > self.ticket_limit
      unless task.class.name == "Shop::Funding"
        return [false, "该款商品当前购买人数已达上限，请稍后看看有没有取消订单的人再来吧。"] if self.is_limit && Shop::OrderItem.where(shop_ticket_type_id: self.id, status: 2).map(&:quantity).sum > self.ticket_limit
      end
    end
    if task.class.name == "Shop::Funding"
      paid_quantity = Shop::FundingOrder.where(user_id: current_user.id, status: 2, shop_ticket_type_id: self.id).map{|o| o.quantity}.sum
    else
      paid_quantity = Shop::OrderItem.where(user_id: current_user.id, status: 2, shop_ticket_type_id: self.id).map{|o| o.quantity}.sum
    end
    return [false, "购买超额了"] if can_equal && quantity > self.can_purchase_limit(paid_quantity)
    return [false, "该订单中有商品已经被下架，请重新提交"] unless self.task.active
    return [false, "该款商品: #{task.title}, 每人限购#{self.each_limit}份, 您已经购买超额啦"] if self.is_each_limit && (paid_quantity + quantity.to_i) > self.each_limit
    return [false, "该商品已购买结束"] if task.sale_end_at < Time.now
    return [false, "该商品购买未开始"] if task.sale_start_at > Time.now
    return [false, "该商品未发布"] unless task.shop_task.published
    address = address_id.present? ? Core::Address.active.find_by_id(address_id) : current_user.addresses.active.by_default.first
    if task.class.name != 'Shop::Funding'
      return [false, "您没有默认地址请重新选择"] if address.blank?
      return [false, "O妹暂不支持表情符号"] if (address.try(:addressee) || "").judge_emoji || (address.try(:address) || "").judge_emoji
    else
      return [false, "您没有默认地址请重新选择"] if task.class.name == 'Shop::Funding' && task.need_address == true && address.blank?
    end
    return [false, "O妹暂不支持表情符号"] if info.judge_emoji
    return [true, "可以购买"]
  end

  #当前价格的商品可购买的人数
  def can_purchase_limit order_size
    can_value = self.ticket_limit - self.participator.value
    can_value = can_value < 0 ? 0 : can_value
    limit = if self.is_limit
      if self.is_each_limit
        if self.each_limit <= can_value
          self.each_limit - order_size < 0 ? 0 : self.each_limit - order_size
        else
          can_value
        end
      else
        can_value
      end
    else
      if self.is_each_limit
        self.each_limit - order_size < 0 ? 0 : self.each_limit - order_size
      else
        99999999
      end
    end
  end
end
