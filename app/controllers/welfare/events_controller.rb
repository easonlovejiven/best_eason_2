class Welfare::EventsController < Home::ApplicationController

  def show
    @task = Welfare::Event.active.find_by(id: params[:id])
    return redirect_to '/', alert: "该任务还未发布" unless @task.present? && @task.shop_task.published?
    #图片

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    @stars = @task.shop_task.core_stars
    @ext_infos = @task.ext_infos
    @parti_users = Rails.cache.fetch("Welfare_event_parti_users_#{params[:id]}", expires_in: 5.minutes) do
      Core::Expen.includes(:user).where(resource_type: @task.class.name, resource_id: @task.id).order(created_at: :asc).paginate(page: 1, per_page: 23).map{|expen| expen.user}
    end
  end

  def more_users
    @task = Welfare::Event.active.find_by(id: params[:id])
    @users = Core::Expen.includes(:user).where(resource_type: @task.class.name, resource_id: @task.id).paginate(page: params[:page] || 1, per_page: params[:per_page] || 16)
  end

  def new
    @event = Welfare::Event.new
  end

  def create
    return redirect_to '/', alert: "普通用户不能发布福利" unless @current_user.verified
    begin
      @event = Welfare::Event.new(welfare_event_params)
      ActiveRecord::Base.transaction do
        @event.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Welfare::Events", action: 'create', event_id: @event.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_welfare_event_path(@event)
    else
      @event.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @event.errors.full_messages.first.blank?
      render :new
    end
  end

  def get_ticket_type
    @task = Welfare::Event.active.find_by(id: params[:id])
    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    render json: {price_types: @price_types, participators: @participators, max_participators: @max_participators, each_limit: @each_limit}
  end

  def buy
    event = Welfare::Event.active.find_by(id: params[:shop_task_id])
    return redirect_to '/', alert: '商品价格发生变化，请重新购买' unless event.present? && event.shop_task.published? && params[:quantity].present?

    fee = (Shop::TicketType.find_by(id: params[:ticket_type_id]).try(:fee) || 0) * (params[:quantity].to_i || 1)
    return redirect_to :back, alert: 'O!不足' unless @current_user.obi >= fee

    ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
    return redirect_to '/', alert: '商品价格发生变化，请重新购买' unless ticket_type.present?
    return redirect_to :back, alert: "该商品已购买结束" if event.sale_end_at.present? && event.sale_end_at < Time.now
    return redirect_to :back, alert: "该款商品: #{ticket_type.task.title}, 每人限购#{ticket_type.each_limit}份, 您已经购买超额啦" if ticket_type.is_each_limit && (Core::Expen.where(user_id: @current_user.id, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum + params[:quantity].to_i) > ticket_type.each_limit
    return redirect_to :back, alert: "该款商品当前购买人数已达上限，请稍后看看有没有取消订单的人再来吧。" if ticket_type.is_limit && ticket_type.participator.value.to_i >= ticket_type.ticket_limit
    ext_infos = []
    infos = event.ext_infos.each_with_index do |v, i|
      return redirect_to :back, alert: "缺少必填的附加信息" if params["info#{i}"].blank? && v.require == true
      return redirect_to :back, alert: "O妹暂不支持表情符号" if params["info#{i}"].judge_emoji
      ext_infos << {ext_info_id: v.id, value: params["info#{i}"]}
    end
    #参与人数增加
    ticket_type.participator.incr(params[:quantity])
    order_no = Digest::MD5.hexdigest("#{Time.now}_#{params[:shop_task_id]}_#{rand(100000...999999)}")
    Redis.current.set("welfare_order_by_#{order_no}", {order_no: "#{order_no}", sum_fee: ticket_type.fee.to_f.round(2), welfare_type: "Welfare::Event", welfare_id: params[:shop_task_id], created_at: Time.now.to_s(:db) }.to_json )
    event.shop_task.payment_obi(@current_user, order_no: order_no, quantity: params[:quantity], fee: fee, ext_infos: ext_infos, shop_ticket_type_id: ticket_type.id, status: :complete)
    CoreLogger.info(controller: "Welfare::Events", action: 'buy', quantity: params[:quantity],fee: fee, ext_infos: ext_infos, shop_ticket_type_id: ticket_type.id, status: :complete, current_user: @current_user.try(:id))
    redirect_to welfare_expens_path, notice: "订单已经在队列中，请稍候查看。"
  end

  def edit
    @event = Welfare::Event.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @event.present?
    raise "没有权限" unless @event.user_id == @current_user.id
  end

  def update
    @event = Welfare::Event.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @event.user_id == @current_user.id && @current_user.verified
    welfare_event_params[:star_list].map do |star|
      next unless star.present?
      return redirect_to :back, alert: "您发布的明星不在我们的列表中哦， 请联系客服添加。"  unless Core::Star.active.published.find_by(id: star).present?
    end
    begin
      ActiveRecord::Base.transaction do
        @event.update!(welfare_event_params) && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Welfare::Events", action: 'update', event_id: @event.try(:id), current_user: @current_user.try(:id))
      if @event.shop_task.try(:published) == true
        render '/home/home/_step3', locals: {path: welfare_event_path(@event), action: 'update'}
      else
        redirect_to preview_welfare_event_path(@event)
      end
    else
      @event.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @event.errors.full_messages.first.blank?
      render :edit
    end
  end

  def preview
    @task = Welfare::Event.active.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @task.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @task.shop_task.published == true

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => 0}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    @stars = @task.shop_task.core_stars
    @ext_infos = @task.ext_infos
  end

  private

  def authorized?
    true
  end

  def welfare_event_params
    params.require(:welfare_event)
      .permit(:id, :user_id, :creator_id, :title, :description, :descripe_key, :sale_start_at, :sale_end_at, :start_at, :end_at, :address, :mobile, :kind,
        star_list: [], ticket_types_attributes: [:category, :second_category, :category_id, :task_id, :task_type, :id, :ticket_limit, :is_limit, :original_fee, :fee, :is_each_limit, :each_limit, :_destroy], ext_infos_attributes: [:id, :title, :task_id, :require, :task_type, :_destroy] )
  end

end
