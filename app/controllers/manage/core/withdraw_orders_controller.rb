class Manage::Core::WithdrawOrdersController < Manage::Core::ApplicationController
  def download
    order = Core::WithdrawOrder.find_by!(id: params[:id])
    exported_file = Core::ExportedOrder.find_by(id: order.core_exported_order_id)
    path = "http://#{Rails.application.secrets.qiniu_host}/#{exported_file.file_name.current_path}"
    CoreLogger.info(controller: 'Manage::Core::WithdrawOrders', action: 'download', id: params[:id], current_user: @current_user.try(:id))
    redirect_to path
  end

  def manual_download
    @order = Core::WithdrawOrder.find_by!(id: params[:id])
    options = {
      withdraw_order_id: @order.id,
      user_id: @current_user.id,
      user_type: "Manage::User",
      task_id: @order.task_id,
      task_type: @order.task_type,
      order_class: @order.task_type == 'Shop::Funding' ? 'Shop::FundingOrder' : 'Shop::OrderItem'
    }
    ExportWorker.perform_async('xlsx', "withdraw_ordes_#{Time.now.to_s(:db)}.xlsx", options)
    CoreLogger.info(controller: 'Manage::Core::WithdrawOrders', action: 'manual_download', id: params[:id], current_user: @current_user.try(:id))
    redirect_to manage_core_withdraw_orders_path
  end
end
