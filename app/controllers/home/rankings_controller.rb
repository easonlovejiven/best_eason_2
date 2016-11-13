class Home::RankingsController < Home::ApplicationController
  def stars
    @stars = Core::Star.except_omei.published.populars.paginate(page: params[:page] || 1, per_page: params[:per] || 16).order(created_at: :desc)
  end

  def fans_will
    @users = Core::User.active.where(identity: 1).populars.paginate(page: params[:page] || 1, per_page: params[:per] || 16)
  end

  def authorized?
    super
    return true if %w[stars fans_will].include?(params[:action])
    !!@current_user
  end
end
