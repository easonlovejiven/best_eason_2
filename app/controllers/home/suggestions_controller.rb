class Home::SuggestionsController < Home::ApplicationController
  def index
    # tasks = if %w(events fundings topics questions subjects media).include? params[:category].to_s
    #   # @current_user.feeds.all.where(category: 'task').send(params[:category])
    #   Shop::Task.tasks.send(params[:category])
    # else
    #   @current_user.feeds.change
    # end
    tasks = @current_user.feeds.change
    tasks = tasks.send(params[:category]) if %w(events fundings topics questions subjects media letters voices welfare_events welfare_products).include? params[:category].to_s
    tasks_scope = case[:order]
    when "hot"
      tasks.populars
    when "time"
      tasks.newests
    else
      tasks.tops
    end
    @tasks = tasks_scope.published.paginate(page: params[:page] || 1, per_page: params[:per_page] || 12)
  end

  def banners
    data = [
      {
        "cover": "http://7oxirl.com1.z0.glb.clouddn.com/owhat2222.jpg",
        "href": "",
        "active": true,
        "hash": "ea73923bc1033b4c0f50b550fafe1866c4bef6c8",
        "start_time": nil,
        "end_time": nil,
        "link": nil,
        "duration": 9999999999
      }
    ]
    render json: data
  end

  def authorized?
    super
    return true if %w[banners].include?(params[:action])
    !!@current_user
  end
end
