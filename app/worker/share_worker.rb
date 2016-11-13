class ShareWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'share', retry: true, backtrace: true
  #新浪分享
  def perform(order_no, category)
    p "-----------自动分享  #{order_no} #{category}"
    case category
    when 'Shop::Funding'
      order = Shop::FundingOrder.where(order_no: order_no).first
      if order.present?
        order.weibo_auto_share
      end
    end
  end
end
