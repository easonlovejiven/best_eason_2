class Home::BackendController < Home::ApplicationController
  before_filter :m_login_filter

  #用户管理后台
  def manage
    @total_pay_orders = Rails.cache.fetch("total_pay_orders_by_#{@current_user.id}", expires_in: 60.minutes) do
      p_orders = Shop::OrderItem.active.where(owner_id: @current_user.id, status: 2).size
      f_orders = Shop::FundingOrder.active.where(owner_id: @current_user.id, status: 2).size
      p_orders + f_orders
    end
    @total_orders = Rails.cache.fetch("total_orders_by_#{@current_user.id}", expires_in: 60.minutes) do
      p_orders = Shop::OrderItem.active.where(owner_id: @current_user.id).size
      f_orders = Shop::FundingOrder.active.where(owner_id: @current_user.id).size
      p_orders + f_orders
    end
    @total_sum = Rails.cache.fetch("total_sum_by_#{@current_user.id}", expires_in: 60.minutes) do
      p_payments = Shop::OrderItem.active.where(owner_id: @current_user.id, status: 2).map(&:payment).sum.to_f.round(2)
      f_payments = Shop::FundingOrder.active.where(owner_id: @current_user.id, status: 2).map(&:payment).sum.to_f.round(2)
      (p_payments + f_payments).to_f.round(2)
    end
  end

  #用户订单管理后台
  def tasks
    shop_type = params[:shop_category] == 'shop_events' ? 'Shop::Event' : params[:shop_category] == 'shop_products' ? 'Shop::Product' : 'Shop::Funding'
    if params[:title].present?
      query = []
      limit = (params[:per] || 10).to_i
      offset = ((params[:page] || 1).to_i - 1) * limit
      query_option = {where: {active: true, shop_type: shop_type, user_id: @current_user.id, published: true}, order: {id: :desc}, fields: [:title], limit: limit, offset: offset, page: params[:page] || 1}
      query_option[:where] = query_option[:where].merge({shop_id: params[:id]}) if params[:id].present?
      query << params[:title] if params[:title].present?
      query << query_option
      @tasks = Shop::Task.search(*query)
      case params[:shop_category]
      when 'shop_events'
        @shops = Shop::Event.where(id: @tasks.map(&:shop_id))
      when 'shop_products'
        @shops = Shop::Product.where(id: @tasks.map(&:shop_id))
      when 'shop_fundings'
        @shops = Shop::Funding.where(id: @tasks.map(&:shop_id))
      end
    else
      @tasks = Shop::Task.where(active: true, shop_type: shop_type, user_id: @current_user.id, published: true)
      @tasks = @tasks.where(shop_id: params[:id]) if params[:id].present?
      @tasks = @tasks.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per] || 10)
      case params[:shop_category]
      when 'shop_events'
        @shops = Shop::Event.active.where(id: @tasks.map(&:shop_id), user_id: @current_user.id).order(id: :desc)
      when 'shop_products'
        @shops = Shop::Product.active.where(id: @tasks.map(&:shop_id), user_id: @current_user.id).order(id: :desc)
      when 'shop_fundings'
        @shops = Shop::Funding.active.where(id: @tasks.map(&:shop_id), user_id: @current_user.id).order(id: :desc)
      end
    end
  end

  def welfares
    shop_type = params[:shop_category] == 'welfare_events' ? 'Welfare::Event' : 'Welfare::Product'
    if params[:title].present?
      query = []
      limit = (params[:per] || 10).to_i
      offset = ((params[:page] || 1).to_i - 1) * limit
      query_option = {where: {active: true, shop_type: shop_type, user_id: @current_user.id, published: true}, order: {id: :desc}, fields: [:title], limit: limit, offset: offset, page: params[:page] || 1}
      query_option[:where] = query_option[:where].merge({shop_id: params[:id]}) if params[:id].present?
      query << params[:title] if params[:title].present?
      query << query_option
      @tasks = Shop::Task.search(*query)
      case params[:shop_category]
      when 'welfare_events'
        @shops = Welfare::Event.where(id: @tasks.map(&:shop_id))
      when 'welfare_products'
        @shops = Welfare::Product.where(id: @tasks.map(&:shop_id))
      end
    else
      @tasks = Shop::Task.where(active: true, shop_type: shop_type, user_id: @current_user.id, published: true)
      @tasks = @tasks.where(shop_id: params[:id]) if params[:id].present?
      @tasks = @tasks.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per] || 10)
      case params[:shop_category]
      when 'welfare_events'
        @shops = Welfare::Event.active.where(id: @tasks.map(&:shop_id), user_id: @current_user.id).order(id: :desc)
      when 'welfare_products'
        @shops = Welfare::Product.active.where(id: @tasks.map(&:shop_id), user_id: @current_user.id).order(id: :desc)
      end
    end
  end

  def expens
    @task = params[:shop_category] == 'Welfare::Event' ? Welfare::Event.find_by(id: params[:task_id]) : Welfare::Product.find_by(id: params[:task_id])
    @expens = Core::Expen.active.includes(:user).where(resource_id: params[:task_id], resource_type: params[:shop_category])
    @expens = @expens.where(order_no: params[:order_no]) if params[:order_no]
    @expens = @expens.paginate(page: params[:page] || 1, per_page: params[:per] || 10).order(created_at: :desc)
  end

  #订单管理界面
  def orders
    if params[:shop_category] == 'Shop::Funding'
      @task = Shop::Funding.active.find_by(id: params[:task_id])
      @orders = Shop::FundingOrder.active.where(shop_funding_id: params[:task_id])
      @orders = @orders.where(status: params[:status]) if params[:status].present?
      @orders = @orders.where(order_no: params[:order_no]) if params[:order_no].present?
      @orders = @orders.paginate(page: params[:page] || 1, per_page: params[:per] || 10).order(created_at: :desc)
    else
      @task = params[:shop_category] == 'Shop::Event' ? Shop::Event.find_by(id: params[:task_id]) : Shop::Product.find_by(id: params[:task_id])
      @orders = Shop::OrderItem.active.where(owhat_product_id: params[:task_id], owhat_product_type: params[:shop_category])
      @orders = @orders.where(status: params[:status]) if params[:status].present?
      @orders = @orders.where(order_no: params[:order_no]) if params[:order_no].present?
      @orders = @orders.paginate(page: params[:page] || 1, per_page: params[:per] || 10).order(created_at: :desc)
    end
  end

  def expen_show
    @expen = Core::Expen.active.find_by(order_no: params[:order_no])
    @ext_info_values = @expen.ext_info_values
    @ext_infos = Hash[Shop::ExtInfo.where(id: @ext_info_values.map(&:ext_info_id)).map{|e| [e.id, e.title]}]
    @user = @expen.user
  end

  def order_show
    case params[:shop_category]
    when 'Shop::Event'
      @order = Shop::OrderItem.active.find_by(order_no: params[:order_no])
    when 'Shop::Product'
      @order = Shop::OrderItem.active.find_by(order_no: params[:order_no])
    when 'Shop::Funding'
      @order = Shop::FundingOrder.active.find_by(order_no: params[:order_no])
    end
  end


  #导出订单
  def export
    CoreLogger.info(controller: 'Home::Backend', action: 'export', task_id: params[:task_id], shop_category: params[:shop_category], current_user: @current_user.try(:id))
    options = {
      user_id: current_user.id,
      user_type: "Core::User",
      task_id: params[:task_id],
      task_type: params[:shop_category],
      order_class: params[:shop_category] == 'Shop::Funding' ? 'Shop::FundingOrder' : ((params[:shop_category] == 'Welfare::Event' || params[:shop_category] == 'Welfare::Product') ? 'Core::Expen' : 'Shop::OrderItem')
    }
    respond_to do |format|
      format.csv {
        filename = "orders-#{params[:task_id]}-#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
        ExportWorker.perform_async('csv', filename, options)
        redirect_to :back, notice: "CSV文件正在导出，请稍后在【查找导出文件】的页面中进行下载。"
      }
      format.xlsx {
        filename = "orders-#{params[:task_id]}-#{Time.now.strftime("%Y%m%d%H%M%S")}.xlsx"
        ExportWorker.perform_async('xlsx', filename, options)
        redirect_to :back, notice: "Xlsx文件正在导出，请稍后在【查找导出文件】的页面中进行下载。"
      }
    end
  end

  #查看已下载订单
  def exported_orders
    @exported_orders = @current_user.exported_orders.order("created_at DESC")
  end

  #下载订单from qiniu
  def download
    CoreLogger.info(controller: 'Home::Backend', action: 'download', exported_order_id: params[:id], current_user: @current_user.try(:id))
    exported_file = @current_user.exported_orders.find_by!(id: params[:id])
    path = "http://#{Rails.application.secrets.qiniu_host}/#{exported_file.file_name.current_path}"
    redirect_to path
  end

  # 财务管理
  def withdraw
    @withdraw_orders = Core::WithdrawOrder.where(requested_by: current_user.try(:id))
    @withdraw_orders = @withdraw_orders.where(task_id: params[:task_id]) if params[:task_id].present?
    @withdraw_orders = @withdraw_orders.where(task_type: params[:task_type]) if params[:task_type].present?
    @orders_total_amount = Shop::OrderItem.where(status: 2, owner_id: @current_user.id).map(&:payment).sum.to_f.round(2)
    @fundings_total_amount = Shop::FundingOrder.where(status: 2, owner_id: @current_user.id).map(&:payment).sum.to_f.round(2)
    @total_amount = (@orders_total_amount + @fundings_total_amount).to_f.round(2)
    @available_withdraw_amount = Core::WithdrawOrder.where(status: [1, 3], requested_by: @current_user.id).map(&:amount).sum.to_f.round(2)
    @total_un_withdrawn_amount = (@total_amount - @available_withdraw_amount).to_f.round(2)
    @total_un_withdrawn_amount = @total_un_withdrawn_amount < 0 ? 0 : @total_un_withdrawn_amount
    @dongjie_amount = Core::WithdrawOrder.where(status: 1, requested_by: @current_user.id).map(&:amount).sum.to_f.round(2)

    @withdraw_orders = @withdraw_orders.paginate(page: params[:page] || 1, per_page: params[:per] || 10).order(created_at: :desc)
  end

  def withdraw_show
    @withdraw_order = Core::WithdrawOrder.find_by(id: params[:id])
  end

  def withdraw_new
    return redirect_to :back, notice: "提现要填任务id哦！" unless params[:task_id].present?
    # return redirect_to :back, notice: "别忘了填申请截止时间呀！" unless params[:requested_at].present?
    # @requested_at = params[:requested_at]
    @requested_at = Time.now.beginning_of_day.to_s(:db)
    @task_id = params[:task_id]
    @task_type = params[:task_type]
    @task = eval(@task_type).find_by(id: params[:task_id])
    return redirect_to :back, notice: "这个不是您开的活动呀，不能提现啊！" unless @task.try(:user_id) == @current_user.id
    if params[:task_type] == 'Shop::Funding'
      @amount = Shop::FundingOrder.active.where(shop_funding_id: params[:task_id], status: 2).where('paid_at < ?', @requested_at).map(&:payment).sum.to_f.round(2) - Core::WithdrawOrder.where(task_id: params[:task_id], task_type: params[:task_type], status: [3, 1]).map(&:amount).sum.to_f.round(2)
      @size = Shop::FundingOrder.active.where(shop_funding_id: params[:task_id], status: 2).where('paid_at < ?', @requested_at).size
    else
      @amount = Shop::OrderItem.active.where(owhat_product_id: @task_id, owhat_product_type: @task_type, status: 2).where('paid_at < ?', @requested_at).map(&:payment).sum.to_f.round(2) - Core::WithdrawOrder.where(task_id: @task_id, task_type: @task_type, status: [3, 1]).map(&:amount).sum.to_f.round(2)
      @size = Shop::OrderItem.active.where(owhat_product_id: @task_id, owhat_product_type: @task_type, status: 2).where('paid_at < ?', @requested_at).size
    end
    @withdraw_order = Core::WithdrawOrder.new
  end

  def withdraw_create
    begin
      core_withdraw_order_params.update({amount: core_withdraw_order_params['amount'].to_f.round(2)})
      @order = Core::WithdrawOrder.new(core_withdraw_order_params)
      ActiveRecord::Base.transaction do
        @order.save!
        SendEmailWorker.perform_async(320, "您有新的提现消息, 来自#{@order.receiver_name}", 'withdraw_order')
        options = {
          withdraw_order_id: @order.id,
          user_id: @current_user.id,
          user_type: "Core::User",
          task_id: core_withdraw_order_params[:task_id],
          task_type: core_withdraw_order_params[:task_type],
          order_class: core_withdraw_order_params[:task_type] == 'Shop::Funding' ? 'Shop::FundingOrder' : 'Shop::OrderItem'
        }
        ExportWorker.perform_async('xlsx', "withdraw_ordes_#{Time.now.to_s(:db)}.xlsx", options)
        CoreLogger.info(controller: 'Home::Backend', action: 'withdraw_create', core_withdraw_order_params: core_withdraw_order_params, current_user: @current_user.try(:id))
        redirect_to withdraw_home_backend_index_path
      end
    rescue ActiveRecord::RecordNotUnique
      flash[:notice] = '不能重复多次提交呀~,点一下就够了！~亲！'
      redirect_to withdraw_home_backend_index_path
    rescue Exception => e
      p e
      flash[:notice] = "提交订单有错误： #{e}"
      redirect_to withdraw_home_backend_index_path
    end
  end

  private

  def m_login_filter
    return render text: "<p>系统升级维护中，后台暂停访问。</p><p>如有特殊情况，请与联系客服：4008980812 。</p>" if Redis.current.get("miaosha").present? && Redis.current.get("miaosha") == 'true'
  end

  def core_withdraw_order_params
    params.require(:core_withdraw_order)
      .permit(:id, :amount, :status, :tickets_count, :receiver_name, :receiver_account, :bank_name, :requestor_remark, :requested_by, :requested_at, :verifier_remark, :verified_at, :verified_by, :cut_off_at, :mobile, :email, :task_id, :task_type,
      pictures_attributes: [:pictureable_id, :pictureable_type, :cover] )
  end

end
