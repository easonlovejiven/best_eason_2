class NotificationSendWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'send_notification'
  
  def perform
    Notification::Send.where("send_date <= ? AND send_status = 1", Time.now).each { |send| send.send_from_rong }
  end

end