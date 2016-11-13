module Core
  module UserHelper
    extend ActiveSupport::Concern

    included do |base|
      after_create :create_shop_cart
      after_create :create_milestone
      # after_update :update_obi_and_empirical_value
      after_update :update_info
    end

    #创建购物车
    def create_shop_cart
      cart = Shop::Cart.create(uid: self.id)
    end

    #注册创建里程碑
    def create_milestone
      #{ "2016-01" => [ {}, {}, {} ] }
      time = Time.now.strftime("%Y-%m")
      if Redis.current.get("User:Milestone:#{self.id}").present?
        milestone = JSON.parse(Redis.current.get("User:Milestone:#{self.id}"))
        if milestone['time']
          stone_arr = milestone['time'].push({ 'owhat_product_type' => 'sign', 'title' => '注册了Q!what~', 'created_at' => Time.now.strftime("%Y-%m-%d"), 'user_pic' => picture_url })
          milestone.update({ time.to_s => stone_arr })
          Redis.current.set("User:Milestone:#{self.id}", milestone)
        else
          Redis.current.set("User:Milestone:#{self.id}", milestone.merge!({ time.to_s => [ { 'owhat_product_type' => 'sign', 'title' => '注册了Q!what~', 'created_at' => Time.now.strftime("%Y-%m-%d"), 'user_pic' => picture_url } ] }))
        end
      else
        Redis.current.set("User:Milestone:#{self.id}", { time.to_s => [ { 'owhat_product_type' => 'sign', 'title' => '注册了O!what~', 'created_at' => Time.now.strftime("%Y-%m-%d"), 'user_pic' => picture_url } ] })
      end
    end

    #更新o币和经验值
    def update_obi_and_empirical_value empirical_value, user
      if (empirical_value < 5)
        level = 0
      elsif (empirical_value >= 5) && empirical_value < 15
        level = 5
        obi = user.obi + 50
      elsif (empirical_value >= 15) && empirical_value < 30
        level = 10
        obi = user.obi + 50
      elsif (empirical_value >= 30) && empirical_value < 50
        level = 15
        obi = user.obi + 100
      elsif (empirical_value >= 50) && empirical_value < 100
        level = 20
        obi = user.obi + 100
      elsif (empirical_value >= 100) && empirical_value < 200
        level = 25
        obi = user.obi + 150
      elsif (empirical_value >= 200) && empirical_value < 500
        level = 30
        obi = user.obi + 150
      elsif (empirical_value >= 500) && empirical_value < 1000
        level = 35
        obi = user.obi + 200
      elsif (empirical_value >= 1000) && empirical_value < 2000
        level = 40
        obi = user.obi + 200
      elsif (empirical_value >= 2000) && empirical_value < 3000
        level = 45
        obi = user.obi + 250
      elsif (empirical_value >= 3000) && empirical_value < 6000
        level = 50
        obi = user.obi + 250
      elsif (empirical_value >= 6000) && empirical_value < 10000
        level = 55
        obi = user.obi + 300
      elsif (empirical_value >= 10000) && empirical_value < 15000
        level = 60
        obi = user.obi + 300
      elsif (empirical_value >= 15000) && empirical_value < 18000
        level = 65
        obi = user.obi + 350
      elsif (empirical_value >= 18000) && empirical_value < 30000
        level = 70
        obi = user.obi + 350
      elsif (empirical_value >= 30000) && empirical_value < 60000
        level = 75
        obi = user.obi + 400
      elsif (empirical_value >= 60000) && empirical_value < 70000
        level = 80
        obi = user.obi + 400
      elsif (empirical_value >= 70000) && empirical_value < 80000
        level = 85
        obi = user.obi + 450
      elsif (empirical_value >= 80000) && empirical_value < 90000
        level = 90
        obi = user.obi + 450
      elsif (empirical_value >= 90000) && empirical_value < 10000
        level = 95
        obi = user.obi + 500
      else
        level = 100
        obi = user.obi + 500
      end
      return level, obi
    end


    def default_address
      addresses.where(active: true, is_default: true).first
    end

    #认证用户账户余额
    def balance_account
      @withdraw_orders = self.withdraw_orders
      @orders_total_amount = Shop::OrderItem.where(status: 2).where(owner_id: id).map(&:payment).sum.to_f.round(2)
      @fundings_total_amount = Shop::FundingOrder.where(status: 2).where(owner_id: id).map(&:payment).sum.to_f.round(2)
      @total_amount = @orders_total_amount + @fundings_total_amount
      @available_withdraw_amount = Core::WithdrawOrder.where(status: 3, requested_by: id).map(&:amount).sum.to_f.round(2)
      @total_un_withdrawn_amount = @total_amount - @available_withdraw_amount
    end

    #认证用户普通用户 o元
    def obi_account
      @obi = Core::TaskAward.where(user_id: id).sum(:obi)
    end

    #经验
    def empirical_account
      Core::TaskAward.where(user_id: id).sum(:empirical_value)
    end

    #是否更新过相关个人信息
    def update_info
      # if pic_changed?
    end

  end
end
