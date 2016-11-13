class Shop::TasksController < Shop::ApplicationController
  def index
    tasks = Shop::Task.tasks.expired.published
    tasks = tasks.send(params[:category]) if %w(events fundings topics questions subjects media).include? params[:category].to_s
    tasks_scope = case params[:order]
    when "hot"
      tasks.populars
    when "time"
      tasks.newests
    else
      tasks.tops
    end
    @tasks = tasks_scope.paginate(page: params[:page] || 1, per_page: params[:per_page] || 12)
  end

  def publish
    task = Shop::Task.active.find params[:id]
    return redirect_to :back, alert: "该任务不存在！" unless task.active
    task.update(published: true)
    TaskWorker.perform_async(task.id, 'create', (JSON.parse(task.star_list.to_s) || {}).reject{|v| v.blank? } )
    CoreLogger.info(controller: "Shop::Tasks", action: 'publish', task_id: task.try(:id), current_user: @current_user.try(:id))
    respond_to do |format|
      format.html { render '/home/home/_step3', locals: {path: task.shop_type == 'Shop::Media' ? "#{task.shop.url}" : "/#{Shop::Task::CATEGORY_PATH[task.shop_type]}/#{task.shop_id}", action: 'create'} }
      format.json { render json: { success: true } }
    end
  end

  def destroy
    task = Shop::Task.find params[:id]
    task.update(active: false)
    task.shop.update(active: false)
    CoreLogger.info(controller: "Shop::Tasks", action: 'destroy', task_id: task.try(:id), current_user: @current_user.try(:id))
    respond_to do |format|
      format.html { redirect_to drafts_home_users_path }
      format.json { render json: { success: true } }
    end
  end

  private

  def authorized?
    super
    return true if %w[index].include?(params[:action])
    !!@current_user
  end
end
