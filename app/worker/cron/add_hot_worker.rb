class AddHotWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'add_hot'

  def perform
    Shop::OrderItem.where("created_at > ? AND created_at < ?", (Time.now - 1.days), Time.now).each do |item|
      next item.payment == 0 || item.status != 2
      task = item.owhat_product.task
      star_list = task.star_list
      star_list.each do |star_id|
        star = Core::Star.find(star_id.to_i)
        star.update(participants: item.quantity)
      end
    end

    Core::User.active.where(verified: true).each do |user|
      followers_count = user.followers_scoped.where("created_at >= ?", 1.day.ago).count
      user.update(participants: user.participants+followers_count)
    end
  end
end
