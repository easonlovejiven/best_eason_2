class Welfare::ExpensController < Home::ApplicationController

  #用户订单界面
  def index
    @expens = Core::Expen.active.shop.where(user_id: @current_user.id).paginate(page: params[:page] || 1, per_page: params[:per] || 10).order(created_at: :desc)
  end

  def show
    @expen = Core::Expen.find_by(id: params[:id])
    @task = @expen.resource
    @ext_info_values = @expen.ext_info_values
    @ext_infos = Hash[Shop::ExtInfo.where(id: @ext_info_values.map(&:ext_info_id)).map{|e| [e.id, e.title]}]
    return raise '没有权限' if @expen.user_id != @current_user.try(:id)
  end

end
