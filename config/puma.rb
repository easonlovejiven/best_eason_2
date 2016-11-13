# Default to production
rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env

# Change to match your CPU core count
workers 2

# Min and Max threads per worker
threads 2, 16
shared_dir = "/mnt/webserver/www/owhat3/shared"

# Set master PID and state locations
pidfile "#{shared_dir}/tmp/pids/puma.pid"
state_path "#{shared_dir}/tmp/sockets/puma.state"
# Logging
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

# Set up socket location
bind "unix://#{shared_dir}/tmp/sockets/puma.sock"





preload_app!
activate_control_app

on_worker_boot do
  require "active_record"
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML.load_file("#{shared_dir}/config/database.yml")[rails_env])
end
