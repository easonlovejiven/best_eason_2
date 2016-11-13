class Manage::Core::ExportedOrdersController < Manage::Core::ApplicationController

  #下载订单from qiniu
  def download
    exported_file =Core::ExportedOrder.find_by!(id: params[:id])
    path = "http://#{Rails.application.secrets.qiniu_host}/#{exported_file.file_name.current_path}"
    CoreLogger.info(controller: 'Manage::Core::ExportedOrders', action: 'download', resource_id: params[:id], current_user: @current_user.try(:id))
    redirect_to path
  end

end
