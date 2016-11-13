class Core::ExportedOrder < ActiveRecord::Base
  include ActAsActivable
  include Redis::Objects
  mount_uploader :file_name, ExportedFileUploader

  belongs_to :user, polymorphic: true
  belongs_to :task, polymorphic: true

  validate :validate_time_and_task_id

  def validate_time_and_task_id
    if (paid_start_at.present? && paid_end_at.present?) || (paid_start_at.blank? && paid_end_at.blank?)
      if paid_start_at.present? && paid_end_at.present?
        unless paid_start_at <= paid_end_at
          errors.add(:paid_start_at, "结束时间必须晚于开始时间，请确认后重试。")
        end
      else
        errors.add(:paid_start_at, "任务信息和支付时间均为空，无法导出订单。请至少选择一项。") if task_id.blank?
      end
    else
      errors.add(:paid_start_at, "支付时间的开始时间和结束时间必须同时选择，请检查。")
    end
    errors.add(:task_type, "任务信息里的任务类型和任务ID必须同时选择/填写，请检查。") if task_id.present? && task_type.blank?
    errors.add(:task_id, "该任务不存在。") if task_id.present? && task_type.present? && (eval(task_type).where('id = ?', task_id).first.blank?)
    errors.add(:task_type, "导出失败，请重试。") if task_id.blank? && order_class.blank?
  end

  def name
    file_name.path.split("/").last if file_name.path
  end

  def all_orders(option = {})
    if task_id.present?
      case task_type
      when 'Shop::Event', 'Shop::Product'
        orders = Shop::OrderItem.where(status:2, owhat_product_id: task_id, owhat_product_type: task_type, active: true)
        orders = orders.where('payment > 0') if exclude_free
        orders = orders.where('paid_at between ? and ?', paid_start_at, paid_end_at ) if paid_start_at.present? && paid_end_at.present?
      when 'Shop::Funding'
        orders = Shop::FundingOrder.where(status:2, shop_funding_id: task_id, active: true)
        orders = orders.where('payment > 0') if exclude_free
        orders = orders.where('paid_at between ? and ?', paid_start_at, paid_end_at ) if paid_start_at.present? && paid_end_at.present?
      when 'Welfare::Event', 'Welfare::Product'
        orders = Core::Expen.where(resource_id: task.id, resource_type: task_type, active: true)
        orders = orders.where('created_at between ? and ?', paid_start_at, paid_end_at ) if paid_start_at.present? && paid_end_at.present?
      else
        orders = []
      end
    else
      case order_class
      when 'Shop::OrderItem'
        orders = Shop::OrderItem.where(status:2, active: true)
        orders = orders.where(owhat_product_type: task_type) if task_type.present?
        orders = orders.where('payment > 0') if exclude_free
        orders = orders.where('paid_at between ? and ?', paid_start_at, (paid_end_at - paid_start_at) > 7.days ? (paid_start_at + 7.days) : paid_end_at ) if paid_start_at.present? && paid_end_at.present?
      when 'Shop::FundingOrder'
        orders = Shop::FundingOrder.where(status:2, active: true)
        orders = orders.where('payment > 0') if exclude_free
        orders = orders.where('paid_at between ? and ?', paid_start_at, (paid_end_at - paid_start_at) > 7.days ? (paid_start_at + 7.days) : paid_end_at ) if paid_start_at.present? && paid_end_at.present?
      when 'Core::Expen'
        orders = Core::Expen.where(active: true, resource_type: ['Welfare::Event', 'Welfare::Product'])
        orders = orders.where(resource_type: task_type) if task_type.present?
        orders = orders.where('created_at between ? and ?', paid_start_at, (paid_end_at - paid_start_at) > 7.days ? (paid_start_at + 7.days) : paid_end_at ) if paid_start_at.present? && paid_end_at.present?
      else
        orders = []
      end
    end
    return orders.count if option[:only_count] == true
    orders
  end

end
