module Shop
  module FundingsHelper
    extend ActiveSupport::Concern

    #完成进度
    def funding_progres
      funding_total_fee = self.funding_total_fee || 0
      return 0 if funding_total_fee.to_f.round(2) == 0 && funding_target.to_f.round(2) * 100 == 0
      return 1 if funding_target.to_f.round(2) == 0
      present = funding_total_fee.to_f.round(2) / funding_target.to_f.round(2) * 100
      (present).round(1)
    end

    #已筹款
    def funding_total_fee
      target = Rails.cache.fetch("shop_funding_total_fee_#{self.id}", expires_in: 5.minutes) do
        Shop::FundingOrder.where(status: 2, shop_funding_id: self.id).map{|f| f.payment.to_f.round(2) }.sum.to_f.round(2)
      end
    end

    #参与人数
    def funding_participators
      self.participator
    end
  end
end
