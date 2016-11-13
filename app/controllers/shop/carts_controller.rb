class Shop::CartsController < Shop::ApplicationController
  # skip_before_filter :login_filter, only: [:index]

  # 加入购物车
  # * 购物车内容 { “user_id”: “{ "ticket_type_id": {"商品title" => "title", "商品单价": "90", "商品数量": "5", "实付款": "158", "商品分类": "看台"}, "ticket_type_id": { “日期”: "2015", "add": "北京", "附件信息": "qq: sss, 微博id: ssss" } }” }
  def add
    #return (redirect_to edit_phone_accounts_path and flash[:notice] = "请先给您的账号进行手机号绑定吧，以后可以直接用手机号登陆啦，方便您以后进行订单查找") unless @current_user.account.phone.present?
    @task = get_task params[:shop_category]
    @ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
    respond_to do |format|
      format.html { return redirect_to :back, alert: "商品信息已发生变化，请返回列表重新购买"}
      format.json { render json: { error: "商品信息已发生变化，请返回列表重新购买" } and return}
    end if @ticket_type.blank?
    ext_infos = "" #附加信息
    split_memo = ""
    if @task.ext_infos.present?
      @infos = @task.ext_infos.each_with_index do |v, i|
        respond_to do |format|
          format.html { return redirect_to :back, alert: "缺少必填的附加信息"}
          format.json { render json: { error: "缺少必填的附加信息" } and return}
        end if v.require == true && params["info#{i}"].blank?
        respond_to do |format|
          format.html { return redirect_to :back, alert: "O妹暂不支持表情符号"}
          format.json { render json: { error: "O妹暂不支持表情符号" } and return}
        end if params["info#{i}"] && params["info#{i}"].judge_emoji
        ext_infos += "#{v.title}: #{params["info#{i}"]}  "
        split_memo += "#{params["info#{i}"]}%&*"
      end
    end

    if params[:commit] == "add_cart"
      Shop::Cart.add_cart(@current_user, @ticket_type, @task, {params: params, ext_infos: ext_infos, split_memo: split_memo})
      CoreLogger.info(controller: "Shop::Carts", action: 'add', data: params, current_user: @current_user.try(:id))
      render json: { status: "ok" } and return
    else
      redirect_to checkout_shop_carts_path(ticket_types: { @task.user_id => [ { "id" => @ticket_type.id, "quantity" => params[:quantity], "info" => ext_infos, "split_memo" => split_memo } ] }, shop_category: @task.shop_category, user_id: @current_user.id)
    end
  end

  #购物车结算界面
  def checkout
    # * "ticket_types"=>{"4"=>[ {"id"=>"19", "info"=>"qq: 287715007  ", "split_memo" =>"", "quantity"=>"2"}, {"id"=>"1", "info"=>"qq: aaaa  ", "quantity"=>"2"} ] }
    ## * 运费hash{98=>{102=>3, 103=>4}, 商品id=>{ticket_type_id=>quantity}}
    return (flash[:notice] = '没有权限' and redirect_to personal_center_home_users_path) if params[:user_id].to_i != @current_user.try(:id)
    @addresses = @current_user.addresses.where(active: true)
    @ticket_types, @products_hash, @tasks, @owhat_product = {}, {}, [], []
    params[:ticket_types].each do |key, types|
      types = (types.is_a?(Array) ? types : types.values.flatten).reject{|t| t["id"].blank? }
      if types.present?
        @ticket_types.merge!({
          Core::User.find_by(id: key).name =>
          types.map do |t|
            type = Shop::TicketType.find_by(id: t['id'])
            @owhat_product << type.task
            task_id = "#{type.task_id}"+"#{type.task_type}"
            if @products_hash.has_key?(task_id)
              @products_hash.update({ task_id => @products_hash[task_id].merge!({ t["id"].to_i => t["quantity"].to_i }) })
            else
              @products_hash.merge!({
                task_id => { t["id"].to_i => t["quantity"].to_i }
              })
            end
            @tasks << task_id
            t.merge!({ ticket_type: type, task: type.task })
          end
        })
      end
    end
    @tasks = @tasks.uniq
    if params[:shop_category] == 'shop_fundings'
      @funding = @owhat_product.first
    end
  end

  def destroy
    unless params[:status] == 'all'
      ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
      if ticket_type.present?
        owner_id = ticket_type.task.user.id
        Shop::Cart.delete_cart(@current_user, owner_id, params)
      else
        Shop::Cart.delete_cart_by_ticket_type_id(@current_user, params[:ticket_type_id])
      end
    else
      cart = @current_user.cart.my_carts.clear
    end
    CoreLogger.info(controller: "Shop::Carts", action: 'destroy', status: params[:status], ticket_type_id: params[:ticket_type_id], current_user: @current_user.try(:id))
    respond_to do |format|
      format.js
    end
  end

  #购物车
  def show
    return (flash[:notice] =  '没有权限' and redirect_to personal_center_home_users_path)  unless @current_user.present?
    @my_carts = Shop::Cart.find_by(uid: @current_user.id).my_carts.all
  end

  def trades

  end

  private

  def get_task shop_category
    case shop_category
    when "shop_events"
      @task = Shop::Event.find_by(id: params[:shop_task_id])
    when "shop_products"
      @task = Shop::Product.find_by(id: params[:shop_task_id])
    when "shop_fundings"
      @task = Shop::Funding.find_by(id: params[:shop_task_id])
    end
  end

end
