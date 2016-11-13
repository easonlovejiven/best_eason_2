class Manage::Core::ExpensController < Manage::PatternsController

  def index
		render text: '', layout: true and return if controller_name.match(/application/)
		@records = model.default(params).includes(model.send(:reflections).keys).shop
	end

  def show
    @record = model.f(id)
		@show = true
    @ext_info_values = @record.ext_info_values
    @ext_infos = Hash[Shop::ExtInfo.where(id: @ext_info_values.map(&:ext_info_id)).map{|e| [e.id, e.title]}]
  end

  def export
    export_data = export_params
    export = Core::ExportedOrder.new(export_data)
    return redirect_to :back, alert: export.errors.messages.values.flatten.join(";") unless export.valid?
    count = export.all_orders(only_count: true)
    CoreLogger.info(controller: 'Manage::Core::Expens', action: 'export', format: params[:format], data: export.to_json, current_user: @current_user.try(:id))
    respond_to do |format|
      filename = "expens-#{current_user.id}-#{export_params[:task_id] || "#{Time.parse(export_data[:paid_start_at]).strftime("%Y%m%d%H%M%S")}" }-#{Time.now.strftime("%Y%m%d%H%M%S")}"
      format.csv {
        ExportWorker.perform_async('csv', "#{filename}.csv", export_data)
        redirect_to :back, notice: "导出订单申请成功，请到  运营 > 导出订单 查看和下载。注意：如果订单数量较大时，系统可能需要5-10分钟处理时间。10分钟内，请勿重复申请导出相同订单。"
      }
      format.xlsx {
        ExportWorker.perform_async('xlsx', "#{filename}.xlsx", export_data)
        redirect_to :back, notice: "导出订单申请成功，请到  运营 > 导出订单 查看和下载。注意：如果订单数量较大时，系统可能需要5-10分钟处理时间。10分钟内，请勿重复申请导出相同订单。"
      }
    end
  end

  private
  def export_params
    {
      user_id: current_user.id,
      user_type: "Manage::User",
      task_id: params["where"]["resource_id"],
      task_type: params["where"]["resource_type"],
      paid_start_at: params["where"]["created_at"][">="],
      paid_end_at: params["where"]["created_at"]["<="],
      order_class: 'Core::Expen'
    }
  end

end
