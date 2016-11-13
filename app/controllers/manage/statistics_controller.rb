class Manage::StatisticsController < Manage::ApplicationController
  def index
    @orders_count = Rails.cache.fetch("hour_get_orders", :expires_in => 1.hours) do
      Shop::Order.active.where(status: 2).count
    end
    @orders = Rails.cache.fetch("hour_get_all_order_items", :expires_in => 1.hours) do
      @orders = Shop::OrderItem.active.where(status: 2)
      @funding_sum = Shop::FundingOrder.where(status: 2).map(&:payment).sum
      [@orders.count, @orders.map(&:payment).sum+@funding_sum]
    end
    @order_items_count = @orders[0]
    @payment = @orders[1]
    @funding_count = Rails.cache.fetch("hour_get_funding_orders", :expires_in => 1.hours) do
      Shop::FundingOrder.active.where(status: 2).count
    end
    @products_count = Rails.cache.fetch("hour_get_products", :expires_in => 1.hours) do
      Shop::Product.active.count
    end
    @fundings_count = Rails.cache.fetch("hour_get_fundings", :expires_in => 1.hours) do
      Shop::Funding.active.count
    end
    @events_count = Rails.cache.fetch("hour_get_events", :expires_in => 1.hours) do
      Shop::Event.active.count
    end
    @user_count = Rails.cache.fetch("hour_get_all_user_count", :expires_in => 1.hours) do
      @user_verified = Core::User.active.where(verified: true).count
      @user_identity = Core::User.active.where(identity: 1).count
      @user_comment = Core::User.active.where(identity: 2).count
      @user_nit = Core::User.active.where(verified: false).count
      [@user_verified, @user_identity, @user_comment, @user_nit]
    end
  end
end
