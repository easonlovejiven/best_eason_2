class CoreLogger
  def self.info data
    ActiveSupport::Notifications.instrument "owhat.event", data
  end
end
