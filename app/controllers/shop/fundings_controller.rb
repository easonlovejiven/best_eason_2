class Shop::FundingsController < Shop::ApplicationController
  skip_before_filter :login_filter, only: [:index]

  def index
    Shop::Funding.active
  end

  def edit
    @funding = Shop::Funding.active.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @funding.present?
    return redirect_to '/', alert: "没有权限" unless @funding.user_id == @current_user.id && @current_user.verified
  end

  def update
    @funding = Shop::Funding.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @funding.user_id == @current_user.id && @current_user.verified
    shop_funding_params[:star_list].map do |star|
      next unless star.present?
      return redirect_to :back, alert: "您发布的明星不在我们的列表中哦， 请联系客服添加。"  unless Core::Star.active.published.find_by(id: star).present?
    end
    begin
      ActiveRecord::Base.transaction do
        @funding.update!(shop_funding_params) && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Fundings", action: 'update', funding_id: @funding.try(:id), current_user: @current_user.try(:id))
      if @funding.shop_task.try(:published) == true
        render '/home/home/_step3', locals: {path: shop_funding_path(@funding), action: 'update'}
      else
        redirect_to preview_shop_funding_path(@funding)
      end
    else
      @funding.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @funding.errors.full_messages.first.blank?
      render :edit
    end
  end

  def show
    return redirect_to '/' unless params[:id].present?
    @task = Shop::Funding.active.find_by(id: params[:id])
    return redirect_to '/', alert: "该任务还未发布" unless @task.present? && @task.shop_task.published?
    #图片
    @covers = []
    (1..3).each{ |i| @covers << @task.cover_url(i) if @task.cover_url(i).present? }

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @each_limit = {}, {}, {}
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) }
    @all_participator = @participators.map{|k, v| v}.sum
    @ext_infos = @task.ext_infos
    @stars = @task.shop_task.core_stars
    @funds = @task.funding_progres #完成进度
    @funding_total_fee = @task.funding_total_fee #已筹款
    @parti_users = Rails.cache.fetch("Shop_funding_parti_users_#{params[:id]}", expires_in: 5.minutes) do
      Shop::FundingOrder.includes(:user).find_by_sql(
        "SELECT user_id, payment, paid_at from (SELECT user_id, sum(payment) as payment, max(paid_at) as paid_at FROM shop_funding_orders WHERE status = 2 AND shop_funding_id = #{@task.id} group by user_id) as orders ORDER BY payment DESC, paid_at ASC LIMIT 10 OFFSET 0"
      ).map{|o|[o.payment.to_f.round(2), o.user]}
    end
  end

  def get_ticket_type
    @task = Shop::Funding.active.find_by(id: params[:id])

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @each_limit = {}, {}, {}
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => t.participator.value}) }
    render json: {price_types: @price_types, participators: @participators, each_limit: @each_limit}
  end

  def show_result
    @task = Shop::Funding.active.find_by(id: params[:id])
  end

  def new
    raise "没有权限" unless @current_user.verified
    @funding = Shop::Funding.new
    @categories = Shop::PriceCategory.all
  end

  def create
    return redirect_to '/', alert: "没有权限" unless @current_user.verified
    begin
      @funding = Shop::Funding.new(shop_funding_params)
      ActiveRecord::Base.transaction do
        @funding.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Fundings", action: 'create', funding_id: @funding.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_shop_funding_path(@funding)
    else
      @funding.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @funding.errors.full_messages.first.blank?
      render :new
    end
  end

  def more_users
    @task = Shop::Funding.active.find_by(id: params[:id])
    @users = Rails.cache.fetch("get_shop_funding_more_users_by_#{@task.id}", :expires_in => 5.minute) do
      Shop::FundingOrder.includes(:user).find_by_sql(
        "SELECT user_id, payment, paid_at from (SELECT user_id, sum(payment) as payment, max(paid_at) as paid_at FROM shop_funding_orders WHERE status = 2 AND shop_funding_id = #{@task.id} group by user_id) as orders ORDER BY payment DESC, paid_at ASC"
      ).map{|o|[o.payment.to_f.round(2), o.user]}
    end
    @users = @users.paginate(page: params[:page] || 1, per_page: params[:per] || 10)
  end

  def preview
    @task = Shop::Funding.active.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @task.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @task.shop_task.published == true
    @covers = []
    (1..3).each{ |i| @covers << @task.cover_url(i) if @task.cover_url(i).present? }

    @ticket_types = @task.ticket_types
    @categories = @ticket_types.group_by{ |t| t.category }
    @price_types, @participators, @each_limit = {}, {}, {}
    @categories.each{|k, v| @price_types.merge!({ k => v.inject({}){|h, t| h[t.id]=[t.second_category, t.fee.to_f]; h}  }) }
    @ticket_types.each{|t| @each_limit.merge!({t.id => t.is_each_limit ? t.each_limit : 99999999}) and @participators.merge!({t.id => 0}) }
    @all_participator = 0
    @ext_infos = @task.ext_infos
    @stars = @task.shop_task.core_stars
    @funds = 0.0 #完成进度
    @funding_total_fee = 0
  end

  private

  def shop_funding_params
    params.require(:shop_funding)
      .permit(:id, :guide, :title, :shop_category, :funding_target, :description, :descripe_cover, :descripe2, :cover1, :cover2, :cover3, :key1, :key2, :key3, :start_at, :end_at, :sale_start_at, :sale_end_at, :address, :mobile, :user_id, :creator_id, :is_share, :free, :need_address,
       star_list: [], ticket_types_attributes: [:category, :second_category, :category_id, :task_id, :task_type, :id, :ticket_limit, :is_limit, :original_fee, :fee, :is_each_limit, :each_limit, :_destroy], ext_infos_attributes: [:id, :title, :task_id, :require, :task_type, :_destroy])
  end

end
