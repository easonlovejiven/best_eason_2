class Notification::SendStatistic < ActiveRecord::Base
  
  belongs_to :notification_send, class_name: "Notification::Send", foreign_key: :send_id

end
