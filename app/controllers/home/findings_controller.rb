class Home::FindingsController < Home::ApplicationController
  def tasks
    @tasks = Shop::Task.tasks.populars
    @tasks = @tasks.send(params[:category]) if %w(events fundings topics questions subjects media).include? params[:category].to_s
    @tasks = @tasks.paginate(page: params[:page] || 1, per_page: 16)
  end

  def stars
    @stars = Core::Star.published.populars.paginate(page: params[:page] || 1, per_page: params[:per_page] || 16)
  end

  def clubs
    @clubs = Core::User.active.where("identity = 1 AND id != #{@current_user.id}").populars.paginate(page: params[:page] || 1, per_page: params[:per_page] || 16)
  end

  def companies
    @companies = Core::User.active.where("identity = 2 AND id != #{@current_user.id}").paginate(page: params[:page] || 1, per_page: params[:per_page] || 16)
  end
end
