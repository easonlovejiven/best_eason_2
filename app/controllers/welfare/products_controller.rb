class Welfare::ProductsController < Home::ApplicationController

  def show
    @task = Welfare::Product.active.find_by(id: params[:id])
    return redirect_to '/', alert: "该任务还未发布" unless @task.present? && @task.shop_task.published?
    #图片

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    @stars = @task.shop_task.core_stars
    @ext_infos = @task.ext_infos
    @parti_users = Rails.cache.fetch("Welfare_product_parti_users_#{params[:id]}", expires_in: 5.minutes) do
      Core::Expen.includes(:user).where(resource_type: @task.class.name, resource_id: @task.id).order(created_at: :asc).paginate(page: 1, per_page: 23).map{|expen| expen.user}
    end
  end

  def more_users
    @task = Welfare::Product.active.find_by(id: params[:id])
    @users = Core::Expen.includes(:user).where(resource_type: @task.class.name, resource_id: @task.id).paginate(page: params[:page] || 1, per_page: params[:per_page] || 16)
  end

  def new
    @product = Welfare::Product.new
  end

  def create
    @product = Welfare::Product.new(welfare_product_params)
    if @product.save
      CoreLogger.info(controller: "Welfare::Products", action: 'create', product_id: @product.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_welfare_product_path(@product)
    else
      render :new
    end
  end

  def create
    return redirect_to '/', alert: "普通用户不能发布福利" unless @current_user.verified
    begin
      @product = Welfare::Product.new(welfare_product_params)
      ActiveRecord::Base.transaction do
        @product.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Welfare::Products", action: 'create', product_id: @product.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_welfare_product_path(@product)
    else
      @product.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @product.errors.full_messages.first.blank?
      render :new
    end
  end

  def get_ticket_type
    @task = Welfare::Product.active.find_by(id: params[:id])
    return redirect_to '/' unless @task.present?
    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    render json: {price_types: @price_types, participators: @participators, max_participators: @max_participators, each_limit: @each_limit}
  end

  def checkout
    @addresses = @current_user.addresses.where(active: true)
    @ticket_type =  Shop::TicketType.find_by(id: params[:ticket_type_id])
    @product = Welfare::Product.active.find_by(id: params[:shop_task_id])
    @fee = (@ticket_type.try(:fee) || 0) * (params[:quantity].to_i || 1)
  end

  def buy
    product = Welfare::Product.active.find_by(id: params[:shop_task_id])
    return redirect_to '/', alert: '商品价格发生变化，请重新购买' unless product.present? || params[:quantity].present? || product.shop_task.published?
    ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
    return redirect_to '/', alert: '商品价格发生变化，请重新购买' unless ticket_type.present?
    ext_infos, show_info, split_memo_string = [], "", ''
    split_memo = params['info'].present? ? params['info'].split("%&*") : []
    infos = product.ext_infos.each_with_index do |v, i|
      return redirect_to :back, alert: "缺少必填的附加信息" if (params["info#{i}"] || split_memo[i]).blank? && v.require == true
      return redirect_to :back, alert: "O妹暂不支持表情符号" if (params["info#{i}"] || split_memo[i]).judge_emoji
      ext_infos << {ext_info_id: v.id, value: (params["info#{i}"] || split_memo[i])}
      show_info += "#{v.title}: #{params["info#{i}"]};" || ""
      split_memo_string += "#{params["info#{i}"]} %&*" if split_memo.blank?
    end
    return redirect_to checkout_welfare_products_path("ticket_type_id" => ticket_type.id, "quantity" => params[:quantity], "show_info" => show_info, "info" => split_memo_string, "shop_task_id" => params[:shop_task_id]) unless params[:address_id].present?
    fee = (Shop::TicketType.find_by(id: params[:ticket_type_id]).try(:fee) || 0) * (params[:quantity].to_i || 1)
    return redirect_to :back, alert: 'O!不足' unless @current_user.obi >= fee
    return redirect_to :back, alert: "该商品已购买结束" if product.sale_end_at.present? && product.sale_end_at < Time.now
    return redirect_to :back, alert: "该款商品: #{ticket_type.task.title}, 每人限购#{ticket_type.each_limit}份, 您已经购买超额啦" if ticket_type.is_each_limit && (Core::Expen.where(user_id: @current_user.id, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum + params[:quantity].to_i) > ticket_type.each_limit
    return redirect_to :back, alert: "该款商品当前购买人数已达上限，请稍后看看有没有取消订单的人再来吧。" if ticket_type.is_limit && ticket_type.participator.value.to_i >= ticket_type.ticket_limit
    #参与人数增加
    ticket_type.participator.incr(params[:quantity])
    order_no = Digest::MD5.hexdigest("#{Time.now}_#{params[:shop_task_id]}_#{rand(100000...999999)}")
    Redis.current.set("welfare_order_by_#{order_no}", {order_no: "#{order_no}", sum_fee: ticket_type.fee.to_f.round(2), welfare_type: "Welfare::Product", welfare_id: params[:shop_task_id], created_at: Time.now.to_s(:db) }.to_json )
    product.shop_task.payment_obi(@current_user, order_no: order_no, quantity: params[:quantity],fee: fee, ext_infos: ext_infos, shop_ticket_type_id: ticket_type.id, status: :complete, address_id: params[:address_id])
    CoreLogger.info(controller: "Welfare::Products", action: 'buy', quantity: params[:quantity],fee: fee, ext_infos: ext_infos, shop_ticket_type_id: ticket_type.id, status: :complete, address_id: params[:address_id], current_user: @current_user.try(:id))
    redirect_to welfare_expens_path, notice: "订单已经在队列中，请稍候查看。"
  end

  def edit
    @product = Welfare::Product.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @product.present?
    raise "没有权限" unless @product.user_id == @current_user.id
  end

  def update
    @product = Welfare::Product.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @product.user_id == @current_user.id && @current_user.verified
    welfare_product_params[:star_list].map do |star|
      next unless star.present?
      return redirect_to :back, alert: "您发布的明星不在我们的列表中哦， 请联系客服添加。"  unless Core::Star.active.published.find_by(id: star).present?
    end
    begin
      ActiveRecord::Base.transaction do
        @product.update!(welfare_product_params) && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Welfare::Products", action: 'update', product_id: @product.try(:id), current_user: @current_user.try(:id))
      if @product.shop_task.try(:published) == true
        render '/home/home/_step3', locals: {path: welfare_product_path(@product), action: 'update'}
      else
        redirect_to preview_welfare_product_path(@product)
      end
    else
      @product.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @product.errors.full_messages.first.blank?
      render :edit
    end
  end

  def preview
    @task = Welfare::Product.active.find_by(id: params[:id])
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

  def welfare_product_params
    params.require(:welfare_product)
      .permit(:id, :user_id, :creator_id, :title, :description, :descripe_key, :sale_start_at, :sale_end_at, :start_at, :end_at, :address, :mobile, :kind,
        star_list: [], ticket_types_attributes: [:category, :second_category, :category_id, :task_id, :task_type, :id, :ticket_limit, :is_limit, :original_fee, :fee, :is_each_limit, :each_limit, :_destroy], ext_infos_attributes: [:id, :title, :task_id, :require, :task_type, :_destroy] )
  end

end
