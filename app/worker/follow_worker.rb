class FollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'follow', retry: true, backtrace: true

  def perform(id, action)
    follow = Follow.find_by_id(id) or return
    case action
    when 'follow' then follow.create_user_feeds
    when 'unfollow' then follow.destroy_user_feeds
    end
  end
end
