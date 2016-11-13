class TaskWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'task', retry: true, backtrace: true

  def perform(id, action, *args)
    sleep 5
    task = Shop::Task.find_by(id: id)
    p "#{Time.now}-------> +++ #{task}"
    p "#{Time.now}-------> task action #{action}"
    task.update_attributes(pic: task.tries(:shop, :cover_pic)) if task
    case action
    when 'create' then task.create_feeds(*args)
    when 'update'
      p "#{Time.now}--------> task update"
      task.update_feeds(*args)
    when 'destroy' then task.remove_feeds(id, *args)
    when 'top' then task.top_feeds
    when 'user'
      Shop::Task.published.where(is_top: true).each do |t|
        next unless t.expired_at.blank? ||  Time.now < t.expired_at
        user_id = Core::User.redis_field_key :feeds, id
        $redis.zadd(user_id, (t.expired_at || 1.year.from_now).utc.strftime("%s%L").to_i, t.id)
      end
    end
  end
end
