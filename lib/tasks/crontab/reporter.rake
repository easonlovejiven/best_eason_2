desc "发送系统报告"
task :reporter => :environment do
  require 'reporter'
  Reporter::Mailer.statistics.deliver
end