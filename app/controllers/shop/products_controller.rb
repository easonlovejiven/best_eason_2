class Shop::ProductsController < Shop::ApplicationController
  skip_before_filter :login_filter, only: [:index, :get_ticket_type, :cart_ticket_type]

  def index
    Shop::Product.active
  end

  def edit
    @product = Shop::Product.active.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @product.present?
    return redirect_to '/', alert: "没有权限" unless @product.user_id == @current_user.id && @current_user.verified
  end

  def update
    @product = Shop::Product.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @product.user_id == @current_user.id && @current_user.verified
    shop_product_params[:star_list].map do |star|
      next unless star.present?
      return redirect_to :back, alert: "您发布的明星不在我们的列表中哦， 请联系客服添加。"  unless Core::Star.active.published.find_by(id: star).present?
    end
    begin
      ActiveRecord::Base.transaction do
        @product.update!(shop_product_params) && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Products", action: 'update', product_id: @product.try(:id), current_user: @current_user.try(:id))
      if @product.shop_task.try(:published) == true
        render '/home/home/_step3', locals: {path: shop_product_path(@product), action: 'update'}
      else
        redirect_to preview_shop_product_path(@product)
      end
    else
      @product.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @product.errors.full_messages.first.blank?
      render :edit
    end
  end

  def new
    raise "没有权限" unless @current_user.verified
    @product = Shop::Product.new
    @categories = Shop::PriceCategory.all
  end

  def show
    return redirect_to '/' unless params[:id].present?
    @task = Shop::Product.active.find_by(id: params[:id])
    return redirect_to '/', alert: "该任务还未发布" unless @task.present? && @task.shop_task.published?
    #图片
    @covers = []
    (1..3).each{ |i| @covers << @task.cover_url(i) if @task.cover_url(i).present? }

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @freights_json, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    @stars = @task.shop_task.core_stars
    @ext_infos = @task.ext_infos
    @freight_template = Shop::FreightTemplate.where(id: @task.freight_template_id).first
    if @freight_template
      @freight_template.freights.each{|f| @freights_json.merge!({f.destination => f.first_fee.to_f.round(2)})}
      @freight = @freight_template.freights.first
    end
    @parti_users = Rails.cache.fetch("Shop_product_parti_users_#{params[:id]}", expires_in: 5.minutes) do
      Shop::OrderItem.includes(:user).find_by_sql(
        "SELECT user_id, payment, paid_at from(SELECT user_id, sum(payment) as payment, max(paid_at) as paid_at FROM shop_order_items WHERE status = 2 AND owhat_product_id = #{@task.id} AND owhat_product_type = '#{@task.class.name}' group by user_id) as orders ORDER BY payment DESC, paid_at ASC LIMIT 10  OFFSET 0 "
      ).map{|o| [o.payment.to_f.round(2), o.user]}
    end
    @surplus_participators = @max_participators.first[1] - @participators.first[1]
  end

  def get_ticket_type
    @task = Shop::Product.find_by(id: params[:id])
    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @freights_json, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    @freight_template = Shop::FreightTemplate.where(id: @task.freight_template_id).first
    if @freight_template
      @freight_template.freights.each{|f| @freights_json.merge!({f.destination => f.first_fee.to_f.round(2)})}
      @freight = @freight_template.freights.first
    end
    render json: {price_types: @price_types, participators: @participators, max_participators: @max_participators, freights_json: @freights_json, each_limit: @each_limit}
  end

  def cart_ticket_type
    @ticket_type = Shop::TicketType.find_by(id: params[:id])
    if @ticket_type.present?
      @each_limit = @ticket_type.is_each_limit ? @ticket_type.each_limit : 99999999
      @surplus = @ticket_type.is_limit ? @ticket_type.ticket_limit - @ticket_type.participator.value : 99999999
      render json: {each_limit: @each_limit, surplus: @surplus}
    else
      render json: {each_limit: 0, surplus: 0}
    end
  end

  def create
    return redirect_to '/', alert: "没有权限" unless @current_user.verified
    begin
      @product = Shop::Product.new(shop_product_params)
      ActiveRecord::Base.transaction do
        @product.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Products", action: 'create', product_id: @product.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_shop_product_path(@product)
    else
      @product.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @product.errors.full_messages.first.blank?
      render :new
    end
  end

  def more_users
    @task = Shop::Product.active.find_by(id: params[:id])
    @users = Rails.cache.fetch("get_shop_product_more_users_by#{@task.id}", :expires_in => 5.minute) do
      Shop::OrderItem.includes(:user).find_by_sql(
        "SELECT user_id, payment, paid_at from(SELECT user_id, sum(payment) as payment, max(paid_at) as paid_at FROM shop_order_items WHERE status = 2 AND owhat_product_id = #{@task.id} AND owhat_product_type = '#{@task.class.name}' group by user_id) as orders ORDER BY payment DESC, paid_at ASC"
      ).map{|o| [o.payment.to_f.round(2), o.user]}
    end
    @users = @users.paginate(page: params[:page] || 1, per_page: params[:per] || 10)
  end

  def preview
    @task = Shop::Product.active.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @task.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @task.shop_task.published == true
    @covers = []
    (1..3).each{ |i| @covers << @task.cover_url(i) if @task.cover_url(i).present? }

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @max_participators, @freights_json, @each_limit = {}, {}, {}, {}, {} #价格， 参与人数 ， 最大参与数量, 运费, json
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => 0}) and @max_participators.merge!({t.id => t.is_limit ? t.ticket_limit : 99999999}) }
    @stars = @task.shop_task.core_stars
    @ext_infos = @task.ext_infos
    @freight_template = Shop::FreightTemplate.find_by(id: @task.freight_template_id)
    if @freight_template
      @freight_template.freights.each{|f| @freights_json.merge!({f.destination => f.first_fee.to_f.round(2)})}
      @freight = @freight_template.freights.first
    end
  end

  private

  def shop_product_params
    params.require(:shop_product)
      .permit(:id, :guide, :title, :shop_category, :description, :descripe_cover, :descripe2, :cover1, :cover2, :cover3, :key1, :key2, :key3, :start_at, :end_at, :sale_start_at, :sale_end_at, :address, :mobile, :user_id, :creator_id, :is_share, :free, :is_need_express, :freight_template_id, :is_rush,
        star_list: [], ticket_types_attributes: [:category, :second_category, :category_id, :task_id, :task_type, :id, :ticket_limit, :is_limit, :original_fee, :fee, :is_each_limit, :each_limit, :_destroy], ext_infos_attributes: [:id, :title, :task_id, :require, :task_type, :_destroy] )
  end

end
