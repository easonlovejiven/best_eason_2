class Manage::Core::UsersController < Manage::Core::ApplicationController
  def create
  end

  def update
    @record = model.f(id)
    change_name = (params["core_user"] || {})["name"]
    @record.name = change_name unless change_name.nil?
    name_result = @record.validate_user_name
    return redirect_to :back, alert: name_result[:msg] if name_result[:status] == false
    data = params.require(param_key).permit(*@record.manage_fields).merge(updater_id: @current_user.id)
    ret = @record.update_with_phone_email(data)
    if ret[:ret]
      CoreLogger.info(controller: "Manage::#{model}", action: 'update', id: @record.try(:id), current_user: @current_user.try(:id), updated_date: data.to_json)
      respond_with(@record) do |format|
        format.html { render :show }
        format.js { head :ok, info: '修改成功！' }
      end
    else
      redirect_to :back, alert: ret[:msg]
    end
  end

end
