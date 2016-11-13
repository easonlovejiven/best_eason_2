class Home::AddressesController < Home::ApplicationController
  # skip_before_filter :login_filter, only: [:index]

  def create
    return redirect_to :back, alert: "省没有选择！" if core_address_params[:province_id] == 0
    @address = Core::Address.new(core_address_params)

    if @address.save
      CoreLogger.info(controller: 'Home::Addresses', action: 'create', address: @address.as_json, current_user: @current_user.try(:id))
      redirect_to addresses_home_users_path
    else
      messages = @address.errors.messages
      redirect_to :back, alert: messages.present? ? "您地址编辑存在异常: #{messages.map{|k, v| "#{I18n.t(k)}：#{v.join("").gsub(/(|)/,'')}"}.join(",")}" : "地址创建不能创建超过50个"
    end
  end

  #更改默认地址
  def default
    @address = Core::Address.find(params[:id])
    @address.set_default

    if params[:ticket_types].present?
      @ticket_types = params[:ticket_types]
      @sum_fee = 0

      @ticket_types.each do |user_name, types|
        types.each_with_index do |type, index|
          @sum_fee += Shop::TicketType.find(type['ticket_type']).fee.to_f.round(2) * type['quantity'].to_i
        end
      end
    end
    CoreLogger.info(controller: 'Home::Addresses', action: 'default', address_id: params[:id], current_user: @current_user.try(:id))
    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :ok }
      format.js
    end
  end

  def edit
    @address = Core::Address.find_by(id: params[:id])
    raise '没有权限操作' if @current_user.id != @address.user_id
  end

  def update
    return redirect_to :back, alert: "省没有选择！" if core_address_params[:province_id] == 0
    @address = Core::Address.find_by(id: params[:id])
    respond_to do |format|
      if @address.update(core_address_params)
        CoreLogger.info(controller: 'Home::Addresses', action: 'update', address: @address.as_json, current_user: @current_user.try(:id))
        format.html { redirect_to addresses_home_users_path }
      else
        format.html { redirect_to edit_home_address_path(params[:id]), alert: @address.errors.messages.map{|k, v| "#{I18n.t(k)}：#{v.join("").gsub(/(|)/,'')}"}.join(",")}
      end
    end
  end

  def destroy
    @address = Core::Address.find_by(id: params[:id])
    respond_to do |format|
      if @address.update(active: false)
        CoreLogger.info(controller: 'Home::Addresses', action: 'destroy', address_id: params[:id], current_user: @current_user.try(:id))
        format.html { redirect_to addresses_home_users_path }
        format.json { head :ok }
        format.js
      end
    end
  end

  private
  def core_address_params
    params.require(:core_address)
      .permit(:id, :user_id, :mobile, :phone, :zip_code, :province_id, :city_id, :district_id, :address, :addressee, :is_default )
  end

end
