class Manage::Shop::OrderItemsController < Manage::PatternsController

  def export
    export_data = export_params
    export = Core::ExportedOrder.new(export_data)
    return redirect_to :back, alert: export.errors.messages.values.flatten.join(";") unless export.valid?
    count = export.all_orders(only_count: true)
    CoreLogger.info(controller: 'Manage::Shop::OrderItems', action: 'export', format: params[:format], data: export.to_json, current_user: @current_user.try(:id))
    respond_to do |format|
      filename = "orders-#{current_user.id}-#{export_params[:task_id] || "#{Time.parse(export_data[:paid_start_at]).strftime("%Y%m%d%H%M%S")}" }-#{Time.now.strftime("%Y%m%d%H%M%S")}"
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
      exclude_free: params["where"]["exclude_free"] == 'true',
      task_id: params["where"]["owhat_product_id"],
      task_type: params["where"]["owhat_product_type"],
      paid_start_at: params["where"]["paid_at"][">="],
      paid_end_at: params["where"]["paid_at"]["<="],
      order_class: 'Shop::OrderItem'
    }
  end

end
