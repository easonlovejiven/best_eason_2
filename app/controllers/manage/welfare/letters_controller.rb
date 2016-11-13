class Manage::Welfare::LettersController < Manage::PatternsController

  def create
    @record = model.new
    params.require(param_key)[:images_attributes] = (params.require(param_key)[:images_attributes] || {}).reject{|k, p| p[:active].to_i == 0 || p[:pic].blank? } || []
    @record.attributes = params.require(param_key).permit(*@record.manage_fields)
    if @record.respond_to?(:creator_id)
      @record.user_id = @current_user.id
      @record.creator_id = @current_user.id
    end
    if @record.save
      CoreLogger.info(controller: 'Manage::Welfare::Letters', action: 'create', id: @record.try(:id), current_user: @current_user.try(:id))
      respond_with(@record) do |format|
        format.html { redirect_to manage_welfare_letter_path(@record) }
        format.js { head :ok, info: '创建成功！' }
      end
    end
  end

  def update
    @record = model.find(params[:id])
    params.require(param_key)[:images_attributes] = params.require(param_key)[:images_attributes].sort_by{|key, attributes| key.to_i }.map{|key, attributes| attributes.slice(*(%w[id pic active])) } if params.require(param_key)[:images_attributes]
    # params.require(param_key)[:images_attributes] = (params.require(param_key)[:images_attributes] || {}).reject{|k, p| p[:active].to_i == 0 || p[:pic].blank? } || []
    @record.attributes = params.require(param_key).permit(*@record.manage_fields)
    if @record.respond_to?(:updater_id)
      @record.updater_id = @current_user.id
    end
    if @record.save
      CoreLogger.info(controller: 'Manage::Welfare::Letters', action: 'update', id: @record.try(:id), current_user: @current_user.try(:id))
      respond_with(@record) do |format|
        format.html { redirect_to manage_welfare_letter_path(@record) }
        format.js { head :ok, info: '修改成功！' }
      end
    end
  end
end
