class Home::UsersController < Home::ApplicationController
  def index

  end

  def login

  end

  #用户收货地址界面
  def addresses
    @address = Core::Address.new
    @addresses = @current_user.addresses.where(active: true)
  end

  #个人中心
  def personal_center
    @welfares = Shop::Task.welfares.includes(:expens).where(core_expens: { user_id: @current_user.id }).order("core_expens.created_at desc").to_a.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10) unless @current_user.verified
    @drafts_count = @current_user.shop_tasks.unpublished.count
  end

  def update
    @user = Core::User.find(params[:id])
    raise '没有权限' if @user.id != @current_user.id
    return render json: { error: "认证的用户需要联系O妹才能修改昵称哟 ~"} if @user.verified? && (params[:core_user] || {})[:name].present? && ((params[:core_user] || {})[:name] != @user.name)
    @user.name = (params[:core_user] || {})[:name] unless (params[:core_user] || {})[:name].nil?
    name_result = @user.validate_user_name
    return render json: { error: name_result[:msg]} if name_result[:status] == false && !(@user.verified?)
    if (params[:core_user]|| {})[:is_auto_share].present? && (params[:core_user]|| {})[:is_auto_share] == 'true'
      user_share_info = @current_user.weibo_auto_share_info
      return render json: { error: "微博无效或未绑定微博", has_weibo: user_share_info[:has_weibo], weibo_token_active: user_share_info[:weibo_token_active]} if user_share_info[:has_weibo] == false || user_share_info[:weibo_token_active] == false
    end
    if @user.verified? ? @user.update_attributes(params[:core_user].permit(:name, :sex, :signature, :is_auto_share)) : @user.update_attributes(params[:core_user].permit(:name, :sex, :signature, :is_auto_share))
      CoreLogger.info(controller: 'Home::Users', action: 'update', user_id: @user.try(:id), data: params[:core_user].permit(:name, :sex, :signature, :is_auto_share), current_user: @current_user.try(:id))
      render json: { }
    else
      render json: { error: "修改失败"}
    end
  end

  def update_birthday
    @user = Core::User.find(params[:id])
    raise '没有权限' if @user.id != @current_user.id

    respond_to do |format|
      if @current_user.update_attribute(:birthday, params[:birthday])
        CoreLogger.info(controller: 'Home::Users', action: 'update_birthday', user_id: @user.try(:id), birthday: params[:birthday], current_user: @current_user.try(:id))
        format.js { render :text => "" }
      else
        format.js { raise "操作失败"}
      end
    end
  end

  # 个人主页 里程碑
  def show
    page = params[:page].present? ? params[:page] : 1
    per_page = params[:per_page].present? ? params[:per_page] : 16
    @user = Core::User.find(params[:id])
    if @user.verified?
      #认证用户
      @feeds = Shop::Task.published.where(user_id: @user.id).joins("LEFT JOIN core_users AS users ON users.id = shop_tasks.user_id")
      @feeds if params[:category].blank?
      @feeds = @feeds.where(category: 'task') if params[:category] == 'task'
      @feeds = @feeds.where(category: 'welfare') if params[:category] == 'welfare'
      @feeds = @feeds.order(created_at: :desc).paginate(page: page, per_page: per_page)
    else
      #普通用户
      if params[:category] == 'task'
        sql1 = "SELECT `o`.owhat_product_id, `o`.user_id AS user_id, `o`.owhat_product_type, `o`.created_at FROM `shop_order_items` AS `o` WHERE `o`.user_id = #{@user.id} AND `o`.status = 2"
        sql2 = "SELECT `f`.shop_funding_id, `f`.user_id AS user_id, `f`.shop_funding_type, `f`.created_at FROM `shop_funding_orders` AS `f`  WHERE `f`.user_id = #{@user.id} AND `f`.status = 2"
        @feeds = Shop::OrderItem.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) ORDER BY created_at DESC").paginate(page: page, per_page: per_page) # LIMIT #{per_page} OFFSET #{(page - 1)*per_page || 0};")
      elsif params[:category] == 'welfare'
        @feeds = Core::Expen.where(user_id: @user.id).order(created_at: :desc).paginate(page: page, per_page: per_page)
      else
        sql1 = "SELECT `o`.owhat_product_id, `o`.user_id AS user_id, `o`.owhat_product_type, `o`.created_at FROM `shop_order_items` AS `o` WHERE `o`.user_id = #{@user.id} AND `o`.status = 2"
        sql2 = "SELECT `f`.shop_funding_id, `f`.user_id AS user_id, `f`.shop_funding_type, `f`.created_at FROM `shop_funding_orders` AS `f`  WHERE `f`.user_id = #{@user.id} AND `f`.status = 2"
        sql3 = "SELECT `w`.resource_id, `w`.user_id AS user_id, `w`.resource_type, `w`.created_at FROM `core_expens` AS `w` WHERE `w`.user_id = #{@user.id}"
        @feeds = Shop::OrderItem.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) UNION ALL (#{sql3}) ORDER BY created_at DESC").paginate(page: page, per_page: per_page)# LIMIT #{per_page} OFFSET #{(page - 1)*per_page || 0};")
      end
    end
  end

  # 编辑资料/个人信息管理
  def edit
    @address = Core::Address.new
    @addresses = @current_user.addresses.where(active: true)
  end


  def update_avatar
    user = Core::User.find(params[:id])

    if user.id == @current_user.id && user.update_attributes(pic: params[:pic])
      CoreLogger.info(controller: 'Home::Users', action: 'update_avatar', user_id: @user.try(:id), pic: params[:pic], current_user: @current_user.try(:id))
      render json: { id: user.id, pic: user.picture_url }
    else
      render json: { error: "操作失败" }
    end
  end

  def update_cover
    @user = Core::User.find(params[:id])
    raise '没有权限' if @user.id != @current_user.id
    respond_to do |format|
      if @current_user.update_attributes(image_id: params[:image_id])
        CoreLogger.info(controller: 'Home::Users', action: 'update_cover', user_id: @user.try(:id), image_id: params[:image_id], current_user: @current_user.try(:id))
        format.js { render text: "操作成功" }
      else
        format.js { raise "操作失败"}
      end
    end
  end

  def follows
    @user = Core::User.find(params[:id])
    @follows = @user.follows_scoped.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
  end

  def followers
    @user = Core::User.find(params[:id])
    @followers = @user.followers_scoped.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
  end

  def welfares
    # @welfares = Shop::Task.welfares.includes(:expens).where(core_expens: { user_id: @current_user.id })
    @expens = @current_user.expens
    @expens = @expens.where(resource_type: Shop::Task::CATEGORY[params[:type]]) if %w(event product letter voice).include?(params[:type].to_s)
    @expens = @expens.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 9)
    # @welfares = @welfares.where(shop_type: Shop::Task::CATEGORY[params[:type]]) if %w(event product letter voice).include?(params[:type].to_s)
    # @welfares = @welfares.order("core_expens.created_at desc").to_a.paginate(page: params[:page] || 1, per_page: params[:per_page] || 9)
  end

  def share_callback
    case params[:type]
    when 'timeline'
      user = Core::User.active.find_by(id: params[:share_id])
      AwardWorker.perform_async(@current_user.id, user.id, user.class.name, 2, 1, 'timeline_share', :award)
    when 'user'
      user = Core::User.active.find_by(id: params[:share_id])
      empirical_value, obi = 2, 1
      AwardWorker.perform_async(@current_user.id, user.id, user.class.name, 2, 1, 'user_share', :award)
    when 'star'
      star = Core::Star.active.find_by(id: params[:share_id])
      AwardWorker.perform_async(@current_user.id, star.id, star.class.name, 2, 1, 'star_share', :award)
    when 'app'
      user = Core::User.active.find_by(id: params[:share_id])
      AwardWorker.perform_async(@current_user.id, user.id, user.class.name, 2, 1, 'app_share', :award)
    when 'topic_dynamic'
      dynamic = Shop::TopicDynamic.find_by(id: params[:share_id])
      dynamic.update(foward_count: dynamic.foward_count+1)
      AwardWorker.perform_async(@current_user.id, dynamic.id, dynamic.class.name, 2, 1, 'topic_dynamic_share', :award)
    else
      task = Shop::Task.active.find_by(id: params[:share_id])
      AwardWorker.perform_async(@current_user.id, task.tries(:shop, :id), task.tries(:shop, :class, :name), 2, 1, 'task_share', :award) if task.tries(:shop, :is_share)
    end
  end

  def owhat
    raise '没有权限' if @current_user.verified?
  end

  def drafts
    @tasks = @current_user.shop_tasks.order("updated_at DESC").need_preview.unpublished.includes(:shop)
    @tasks = @tasks.send(params[:category]) if %w(topics products fundings task_events questions subjects media letters welfare_events welfare_products).include?(params[:category])
    @tasks = @tasks.paginate(page: params[:page] || 1, per_page: params[:per_page] || 9)
    @resource = Hash[@tasks.map{|t| [t.id, t.try(:shop).try(:updated_at)]}]
  end

  def identity
    raise '已认证' if @current_user.verified
    identity = @current_user.identities.active.last
    if identity
      if identity.status == "拒绝"
        redirect_to failure_home_identities_path
      else
        redirect_to success_home_identities_path
      end
      return
    end
    @identity = Core::Identity.new
  end

  def set_auto_share
    respond_to do |format|
      format.json do
        return render json: { error: "未登录", unlogin: true} if @current_user.blank?
        return render json: { error: "参数错误"} if params[:auto_share].blank?
        if params[:auto_share] == 'yes'
          user_share_info = @current_user.weibo_auto_share_info
          return render json: { error: "微博无效或未绑定微博", has_weibo: user_share_info[:token], weibo_token_active: user_share_info[:weibo_token_active]} if user_share_info[:has_weibo] == false || user_share_info[:weibo_token_active] == false
        end
        if @current_user.update_attributes(is_auto_share: params[:auto_share] == 'yes')
          ShareWorker.perform_async(params[:order_no], params[:category]) if params[:auto_share] == 'yes' && params[:order_no].present?  && params[:category].present?
          CoreLogger.info(controller: "Home::Users", action: 'set_auto_share', auto_share: params[:auto_share], order_no: params[:order_no], category: params[:category], current_user: @current_user.try(:id))
          render json: {}
        else
          return render json: { error: "设置失败"}
        end
      end
    end
  end

  def authorized?
    super
    return true if %w[show set_auto_share].include?(params[:action])
    !!@current_user
  end
end
