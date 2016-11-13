require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'
require 'mina/puma'
require 'yaml'
require "mina_sidekiq/tasks"
# require 'mina_sidekiq/tasks'
YAML.load(File.open('config/deploy.yml')).keys.each do |server|
  desc %{Set up #{server} for deployment}
  task "setup_#{server}" => :environment do
    load_config(server)
    invoke :setup
  end
  desc %{deploy to #{server} server}
  task "d_#{server}" => :environment do
    load_config(server)
    invoke :deploy_all
  end

  desc %{start to #{server} server}
  task "s_#{server}" => :environment do
    load_config(server)
    invoke :start_all
  end

  desc %{restart to #{server} server}
  task "r_#{server}" => :environment do
    load_config(server)
    invoke :restart_all
  end
  desc %{stop to #{server} server}
  task "stop_#{server}" => :environment do
    load_config(server)
    invoke :stop_all
  end
end

def load_config(server)
  thirdpillar_config = YAML.load(File.open("config/deploy.yml"))
  puts "———> configuring #{server} server"
  set :user, thirdpillar_config[server]['user']
  # set :domain, thirdpillar_config[server]['domain']
  set :port, thirdpillar_config[server]['port']
  set :deploy_to, thirdpillar_config[server]['deploy_to']
  set :repository, thirdpillar_config[server]['repository']
  set :branch, thirdpillar_config[server]['branch']
  set :rails_env, thirdpillar_config[server]['rails_env']
  set :puma_pid, "#{deploy_to}/shared/tmp/pids/puma.pid"
  set :sidekiq_pid, "#{deploy_to}/shared/tmp/pids/sidekiq.pid"
  # set :shared_paths, ['log']
end

set :user, 'owhat'
set :shared_paths, [ 'config/mailer.yml', 'config/host.yml', 'config/database.yml', 'config/secrets.yml', 'config/sms.yml', 'config/oauth.yml', 'config/sidekiq.yml', 'config/redis.yml', 'config/newrelic.yml', 'log', 'public/image', 'public/uploads', 'public/assets', 'tmp']

set :rvm_path, "/home/owhat/.rvm/scripts/rvm"

task :environment do
  invoke :'rvm:use[ruby-2.2.1]'
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/image"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/image"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/assets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/assets"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/uploads"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/uploads"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/database.yml'."]

  queue! %[touch "#{deploy_to}/shared/config/redis.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/redis.yml'."]

  queue! %[touch "#{deploy_to}/shared/config/sms.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/sms.yml'."]

  queue! %[touch "#{deploy_to}/shared/config/oauth.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/oauth.yml'."]

  queue! %[touch "#{deploy_to}/shared/config/host.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/host.yml'."]

  queue! %[touch "#{deploy_to}/shared/config/mailer.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/mailer.yml'."]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/sockets"]

  # tmp/sockets/puma.state
  queue! %[touch "#{deploy_to}/shared/tmp/sockets/puma.state"]
  queue  %[echo "-----> Be sure to edit 'shared/tmp/sockets/puma.state'."]

  # log/puma.stdout.log
  queue! %[touch "#{deploy_to}/shared/log/puma.stdout.log"]
  queue  %[echo "-----> Be sure to edit 'shared/log/puma.stdout.log'."]

  # log/puma.stdout.log
  queue! %[touch "#{deploy_to}/shared/log/puma.stderr.log"]
  queue  %[echo "-----> Be sure to edit 'shared/log/puma.stderr.log'."]

 # sidekiq needs a place to store its pid file and log file
  # queue! %[mkdir -p "#{deploy_to}/shared/pids/"]
  # queue! %[mkdir -p "#{deploy_to}/shared/log/"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # queue %[ /bin/bash --login ]
    # invoke :'sidekiq:quiet'
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile:force'
    invoke :'deploy:cleanup'
    invoke :restart
    to :launch do
      queue "mkdir -p #{deploy_to}/shared/tmp/"
      invoke :'sidekiq:quiet'
      invoke :'sidekiq:restart'
      # queue "chown -R www-data #{deploy_to}"
      queue "touch #{deploy_to}/shared/tmp/restart.txt"
      # invoke :'sidekiq:restart'
    end
  end
end

desc 'Starts the application'
task :start => :environment do
  desc 'echo "-----> Start Puma"'
  queue "cd #{deploy_to}/current ; bundle exec puma --config #{deploy_to}/current/config/puma.rb -e #{rails_env} -d"
  queue  %[echo "-----> deploy start ok."]
end


desc 'Stops the application'
task :stop => :environment do
  queue 'echo "-----> Stop Puma"'
  queue! %{
        test -s "#{puma_pid}" && kill -QUIT `cat "#{puma_pid}"` && echo "Stop Ok" && exit 0
        echo >&2 "Not running"
      }
end

desc "Restart Puma using 'upgrade'"
task :restart => :environment do
  report_time do
    invoke :stop
    sleep 10
    invoke :start
  end
  queue  %[echo "-----> deployer restart ok."]
end


desc "Deploy to all servers"
task :deploy_all do
  isolate do
    YAML.load(File.open("config/deploy.yml"))["#{rails_env}"]['domains'].each do |domain|
      set :domain, domain
      invoke :deploy
      run!
    end
  end
end

desc "Stop to all servers"
task :stop_all do
  isolate do
    YAML.load(File.open("config/deploy.yml"))["#{rails_env}"]['domains'].each do |domain|
      set :domain, domain
      invoke :stop
      run!
    end
  end
end

desc "Stop to all servers"
task :start_all do
  queue  %[echo "-----> #{rails_env}"]
  isolate do
    YAML.load(File.open("config/deploy.yml"))["#{rails_env}"]['domains'].each do |domain|
      set :domain, domain
      invoke :start
      run!
    end
  end
end

desc "Stop to all servers"
task :restart_all do
  isolate do
    YAML.load(File.open("config/deploy.yml"))["#{rails_env}"]['domains'].each do |domain|
      set :domain, domain
      invoke :restart
      run!
    end
  end
end
