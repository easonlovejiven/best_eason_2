class Qa::ApplicationController < ApplicationController
  # include ApplicationHelper
  # layout 'home/application'
  before_filter :get_users, only:[:show]

  private

  def authorized?
    @enable_lazyload = true

    !!@current_user
  end

  def get_users
    @get_users = Rails.cache.fetch("get_aside_users", :expires_in => 1.hours) do
      if @current_user.present?
        Core::User.active.where("verified = 1 AND id != #{@current_user.id}").order(position: :desc, created_at: :desc).limit(10).sample(3)
      else
        Core::User.active.where("verified = 1").order(position: :desc, created_at: :desc).limit(10).sample(3)
      end
    end
  end
end
