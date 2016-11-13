def flatten_hash hash, head=nil
  hash.class == Hash ? hash.map{|k,v|
    "#{v.class == Hash ? flatten_hash(v,"#{head}#{k}_") : "#{head}#{k}=#{v}"}"
  }.join(",") : hash.to_s
end

class NotifyLogger
  attr_accessor :logger
  def initialize(logger)
    @logger = Logger.new("#{Rails.root}/log/#{logger}.log")
    @logger.formatter = NotifyFormatter.new
  end

  class NotifyFormatter < ::Logger::Formatter
    # This method is invoked when a log event occurs
    def call(severity, timestamp, progname, msg)
      "#{timestamp},#{msg}\n"
    end
  end
end

def notify_logger(logger)
  NotifyLogger.new(logger).logger
end

ActiveSupport::Notifications.subscribe 'owhat.event' do |name, started, finished, unique_id, data|
  logger_file = data.class == Hash && data[:logger].present? ? data[:logger] : 'notify'
  data.delete :logger if data.class == Hash && data[:logger].present?
  data = {data: data} unless data.class == Hash
  data[:source_type] = 'owhat'
  notify_logger(logger_file).info "#{flatten_hash data}"
end
