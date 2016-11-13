class Manage::Notification::SendsController < Manage::PatternsController

  def index
    render text: '', layout: true and return if controller_name.match(/application/)
    @records = 
      case params[:where][:send_status].to_i
      when 2 then model.order(send_date: :desc).default(params)
      when 3 then model.order(updated_at: :desc).default(params)
      else model.order(send_date: :asc).default(params)
      end
  end

  def create
    begin
      @record = Notification::Send.new
      @record.attributes = params.require(param_key).permit(*@record.manage_fields)
      if @record.respond_to?(:creator_id)
        @record.creator_id = @current_user.id
      end
      send_date_judge = (@record.send_date.present? && @record.send_date.to_time <= DateTime.current || @record.send_date.blank?)
      send_type_judge = @record.send_type.to_i.zero?
      original_time = @record.send_date
      @record.send_date = DateTime.current if send_date_judge || send_type_judge
      if @record.save!
      	@record.send_from_rong if send_type_judge
        # 记录原始发送时间
      	CoreLogger.info(controller: "Manage::#{model}", action: 'create', data: @record.to_json, original_time: original_time, current_user: @current_user.try(:id))
        render :show
      end
    rescue Exception => e
      render :show
    end
  end

  def update
    @record = Notification::Send.find(params[:id])
    @record.attributes = params.require(param_key).permit(*@record.manage_fields)
    if @record.respond_to?(:updater_id)
      @record.updater_id = @current_user.id
    end
    send_date_judge = (@record.send_date.present? && @record.send_date.to_time <= DateTime.current || @record.send_date.blank?)
    send_type_judge = @record.send_type.to_i.zero?
    original_time = @record.send_date
    @record.send_date = DateTime.current if send_date_judge || send_type_judge
    if @record.save
    	@record.send_from_rong if send_type_judge
      # 记录原始发送时间
    	CoreLogger.info(controller: "Manage::#{model}", action: 'update', data: @record.to_json, original_time: original_time, current_user: @current_user.try(:id))
    end
    render :show
  end

  def cancel
    @record = Notification::Send.find(params[:id])
    if @record.respond_to?(:updater_id)
      @record.updater_id = @current_user.id
    end
    @record.update_attribute(:send_status, 3)
    redirect_to :back
  end

end
