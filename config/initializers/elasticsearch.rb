ENV["ELASTICSEARCH_URL"] = Rails.application.secrets.elasticsearch_host
Elasticsearch::Model.client = Elasticsearch::Client.new host: Rails.application.secrets.elasticsearch_host
if Rails.env.development? || Rails.env.web? || Rails.env.production?
  tracer = ActiveSupport::Logger.new('log/elasticsearch.log')
  tracer.level =  Logger::DEBUG
end
Elasticsearch::Model.client.transport.tracer = tracer
