module Reporter
  def self.helpers
    Helper
  end

  def self.settings
    @settings ||= {
      mailler: {
        receivers: %w(
        dingjie@owhat.cn
        michael@owhat.cn
        zhoubin@owhat.cn
        wangle@owhat.cn
        ),
      },
      ago: "1 days"
    }
  end

  class Mailer < ActionMailer::Base
    default from: "noreply@owhat.cn"
    append_view_path Rails.root.join("lib")

    def statistics(settings=Reporter.settings)
      options = {ago: settings[:ago]}
      @users    = Users.new(options.dup)
      @tickets  = Tickets.new(options.dup)
      mail(subject: subject(@users.start_at, @users.end_at), to: settings[:mailler][:receivers])
    end

    def subject(start_at, end_at)
      time_string = [start_at, end_at].map {|time| time.strftime("%Y-%m-%d %H:%M:%S") }.join(" 至 ")
      "Owhat #{time_string} 系统统计报告"
    end
  end

  class Base
    delegate :ago, to: :helpers
    attr_accessor :start_at, :end_at

    def initialize(options)
      parse_to_normal_options!(options)
      @start_at = options[:start_at]
      @end_at   = options[:end_at]
    end

    def scope
      raise NotImplementedError
    end

    def helpers
      Reporter.helpers
    end

    protected
    def parse_to_normal_options!(options)
      options[:start_at], options[:end_at] = [Time.now, ago(options.delete(:ago))].sort
      options.assert_valid_keys(:start_at, :end_at)
    end
  end

  class Users < Base

    def counter
      {added: scope.count, total: User.count}
    end

    def doctor
      {
        unrole: unrole.pluck(:id)
      }
    end

    def unrole
      return 0 if normal_role.blank?
      scope.joins("left join users_roles on users_roles.user_id = users.id and users_roles.role_id = #{normal_role.id}").where("users_roles.role_id is null").tap do |users|
        users.find_each {|user| user.add_role :normal}
      end
    end

    def normal_role
      @normal_role ||= Role.find_by_name("normal")
    end

    def scope
      User.where(created_at: start_at..end_at)
    end
  end

  class Tickets < Base
    # {状态 => 数量}
    def counter
      scope.group(:status).count.tap do |h|
        # 待使用的数量合并到已使用中
        h[2]+= h.delete(3) if h[3] && h[2]
      end
    end
    # {状态 => 金额}
    def amounts
      scope.group(:status).sum(:payment).tap do |h|
        # 待使用的数量合并到已使用中
        h[2]+= h.delete(3) if h[3] && h[2]
      end
    end

    def doctor
      {
        unpayment:  unpayment.pluck(:order_no),
        unnotify:   unnotify.pluck(:order_no),
        untreated:  untreated.pluck(:order_no)
      }.reject {|k,v| v.blank?}
    end
    # payment为空
    def unpayment
      scope.where("status > 1 and payment > 0 and alipay_payment_at is null")
    end
    # 短信未通知
    def unnotify
      scope.joins(:event).where(events: {send_sms: true}, tickets: {status: [2,3], paid_sms_sent_at: nil}).tap do |tickets|
        # tickets.find_each { |ticket| SendPaidSmsWorker.perform_async(ticket.id) }
      end
    end
    # 未处理(超时未删除的订单)
    def untreated
      scope.time_out.tap do |ticket|
        # ticket.find_each(&:destroy)
      end
    end

    def scope
      Ticket.where(created_at: start_at..end_at)
    end
  end

  module Helper
    UnitError = Class.new(StandardError)
    NumError = UnitError
    UNITS = %w(seconds minutes hours days weeks months years)
    def ago(string)
      ((num, unit)) = string.to_s.scan(/^(\d+)[ |\.]?([#{UNITS.join("|")}]+)/i)
      raise UnitError, "#{string} (unit) not in #{UNITS.join('|')}" if unit.nil?
      raise NumError, "#{string} number Incorrect" if num.to_i <= 0
      num.to_i.send(unit).ago.beginning_of_day
    end
    extend self
  end
end
