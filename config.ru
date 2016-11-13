# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application

require 'rack/cors'

use Rack::Cors do
  allow do
    origins 'localhost:9000', 'localhost:8090', 'localhost:8000', 'www.owhat.cn', 'owhat.cn', 'localhost:3000', 'dev.owhat.avosapps.com', 'cloud.owhat.cn', 'backend.owhat.dev'
    resource '*', :headers => :any, :methods => [:get, :post, :options, :delete]
  end
end