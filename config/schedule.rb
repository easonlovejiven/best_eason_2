# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, File.expand_path("log/cron.log")
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# every :hour, :roles => [:app] do
#   runner "Event.notify_creaters"
# end

every 2.minutes do
  rake "clear_unpaid_tickets"
end

every 1.minute do
  rake 'fresh_live_room_status'
end

every 1.days do
  rake "disable_feed_hot"
end

every :day, at: "1am" do
  rake "reporter"
end
