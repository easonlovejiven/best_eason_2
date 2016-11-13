class ExportStatisticOrderWorker
  
  include Sidekiq::Worker
  sidekiq_options queue: 'export_statistics'
  
  def perform
    begin_time = Time.now - 7.day
    end_time = begin_time + 7.day
    filename = '报表统计'
    tasks = Shop::Task.includes(:shop, :user).where("created_at > ? AND expired_at < ?", begin_time, end_time).active.published.where(shop_type: ['Shop::Product', 'Shop::Event', 'Shop::Funding'])
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => filename) do |sheet|
        sheet.add_row %W(序列 导出时间 名称 购买开始时间 购买结束时间 发布方 项目类型(活动/商品/应援) 免费/收费 本周订单数量 总订单数 本周售出数 总售出数 本周销售金额(元) 总销售金额合计(元))
        tasks.each_with_index do |task, index|
          next unless task.shop.present?
          index += 1
          orders = task.shop_type == 'Shop::Funding' ? task.shop.funding_orders.order_paid : task.shop.order_items.order_paid
          sheet.add_row [
            index,
            Time.now.strftime("%Y-%m-%d %H:%M:%S"),
            task.title,
            task.shop.sale_start_at ? task.shop.sale_start_at.strftime("%Y-%m-%d %H:%M:%S") : task.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            task.shop.sale_end_at ? task.shop.sale_end_at.strftime("%Y-%m-%d %H:%M:%S") : task.expired_at.strftime("%Y-%m-%d %H:%M:%S"),
            task.user.try(:name),
            task.shop_type == 'Shop::Product' ? '商品' : task.shop_type == 'Shop::Event' ? '活动' : '应援',
            task.shop.free ? '免费' : '收费',
            orders.by_paid_at(begin_time, end_time).count, # 本周订单数
            orders.count, # 总订单数
            orders.by_paid_at(begin_time, end_time).map(&:quantity).sum, # 本周售出数
            orders.map(&:quantity).sum, # 总售出数
            orders.by_paid_at(begin_time, end_time).map(&:payment).sum.to_f, # 本周销售金额
            task.shop.sum_fee #总销售金额合计
          ]
        end
      end
      Core::Mailer.attachment_mail(to: 'houtai@owhat.cn', body: p, subject: "owhat3#{filename} #{begin_time.strftime("%Y-%m-%d")}", filename: filename)
    end
  end

end