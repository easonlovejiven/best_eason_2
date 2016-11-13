class Manage::Shop::TasksController < Manage::PatternsController
  def index
    render text: '', layout: true and return if controller_name.match(/application/)
    if ((params["where"] || {})["title"] || {})["like"].present?
      query = []
      limit = (params[:per_page] || 10).to_i
      offset = ((params[:page] || 1).to_i - 1) * limit
      query_option = {where: {active: true}, fields: [:title], limit: limit, offset: offset, page: params[:page] || 1}
      query_option[:where] = query_option[:where].merge({id: params[:where][:id]}) if (params["where"] || {})[:id].present?
      query << params[:where][:title][:like] if ((params["where"] || {})["title"] || {})["like"].present?
      query_option[:where] = query_option[:where].merge({shop_type: params[:where][:shop_type]}) if (params["where"] || {})[:shop_type].present?
      query_option[:where] = query_option[:where].merge({shop_id: params[:where][:shop_id]}) if (params["where"] || {})[:shop_id].present?
      created_at_query = {}
      created_at_query.merge!({gte: params[:where][:created_time][">="].to_time}) if ((params["where"] || {})[:created_time] || {})[">="].present?
      created_at_query.merge!({lte: params[:where][:created_time]["<="].to_time}) if ((params["where"] || {})[:created_time] || {})["<="].present?
      query_option[:where] = query_option[:where].merge({created_time: created_at_query}) if created_at_query.present?
      order_option = params[:order].present? ? params[:order].split(" ") : ["id", "desc"]
      query_option[:order] = Hash[order_option[0] == 'id' ? 'created_time' : order_option[0], order_option[1]] if order_option.present?
      query << query_option
      @records = model.search(*query)
    else
      @records = @tasks = model.default(params).includes(model.send(:reflections).keys)
    end
  end

  def sync
    @task = Shop::Task.find(params[:id])
    if @task.update_attributes(pic: @task.tries(:shop, :cover_pic), active: @task.shop.active)
      CoreLogger.info(controller: 'Manage::Shop::Tasks', action: 'sync', id: params[:id], current_user: @current_user.try(:id))
      respond_to do |format|
				format.html { redirect_to manage_shop_tasks_path }
				format.js { head :ok, info: '同步成功！' }
			end
    else
      respond_to do |format|
				format.html { redirect_to manage_shop_tasks_path }
				format.js { head :ok, info: '同步失败！' }
			end
    end
  end

  def publish
    @task = Shop::Task.find(params[:id])
    @task.update_attributes(published: true, updater_id: @current_user.id)
    TaskWorker.perform_async(@task.id, 'create', (JSON.parse(@task.star_list.to_s) || {}).reject{|v| v.blank? } )
    CoreLogger.info(controller: 'Manage::Shop::Tasks', action: 'publish', id: params[:id], current_user: @current_user.try(:id)) if @task.valid?
    head @task.valid? ? :accepted : :bad_request
  end

  def unpublish
    @task = Shop::Task.find(params[:id])
    @task.update_attributes(published: false, updater_id: @current_user.id)
    TaskWorker.perform_async(@task.id, 'destroy', (JSON.parse(@task.star_list.to_s) || {}).reject{|v| v.blank? } )
    CoreLogger.info(controller: 'Manage::Shop::Tasks', action: 'unpublish', id: params[:id], current_user: @current_user.try(:id)) if @task.valid?
    head @task.valid? ? :accepted : :bad_reqest
  end
end
