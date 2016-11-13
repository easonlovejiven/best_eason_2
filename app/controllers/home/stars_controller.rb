class Home::StarsController < Home::ApplicationController

  def index
    # @stars = Core::Star.published.order(position: :desc, created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
    stars = Core::Star.published
    @stars = if params[:order] == 'name'
      conv = Iconv.new("GBK//IGNORE", "utf-8")
      stars.sort {|x, y| conv.iconv(x.name) <=> conv.iconv(y.name)}.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
    else
      stars.populars.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
    end
    # conv = Iconv.new("GBK//IGNORE", "utf-8")
    # @stars = Core::Star.published.sort {|x, y| conv.iconv(x.name) <=> conv.iconv(y.name)}.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
  end

  def show
    @star = Core::Star.find(params[:id])
    @tasks = @star.shop_tasks.published.where(category: params[:type] == 'welfare' ? 'welfare' : 'task').newests.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 16)
  end

  def follow
    user = if params[:role] == 'star'
      Core::Star.find_by(id: params[:id])
    else
      Core::User.find_by(id: params[:id])
    end
    raise '关注失败' if user.blank? && user == @current_user

    if !@current_user.following?(user) && @current_user.follow_and_update_cache(user)
      CoreLogger.info(controller: 'Home::Stars', action: 'follow', role: params[:role], follow_id: params[:id], current_user: @current_user.try(:id))
      respond_to do |format|
          format.html
          format.js { render :text => '' }
        end
      else
        respond_to do |format|
          format.html
          format.js { raise "操作失败"}
        end
    end
  end

  def unfollow
    user = if params[:role] == 'star'
      Core::Star.find_by(id: params[:id])
    else
      Core::User.find_by(id: params[:id])
    end
    raise '关注失败' if user.blank? && user == @current_user

    if @current_user.unfollow_and_update_cache(user)
      CoreLogger.info(controller: 'Home::Stars', action: 'follow', role: params[:role], follow_id: params[:id], current_user: @current_user.try(:id))
      respond_to do |format|
        format.html
        format.js { render :text => '' }
      end
    else
      respond_to do |format|
        format.html
        format.js { raise "操作失败" }
      end
    end
  end

  def followers
    @star = Core::Star.find(params[:id])
  end

  private

  def authorized?
    super
    return true if %w[index show].include?(params[:action])
    !!@current_user
  end
end
