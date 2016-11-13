# encoding:utf-8
module V3
  class ShopFundingsApi < Grape::API
    format :json

    before do
      check_sign
    end

    desc "关联明星应援列表"
    params do
      requires :uid, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_fundings_by_star do
      # stars = Core::Star.find_by_sql("SELECT `core_stars`.id, `core_stars`.name, `core_stars`.pic FROM `core_stars` WHERE `core_stars`.`active` = 1 AND `core_stars`.`published` = 1 AND `core_stars`.`id` IN (select  core_star_id from shop_task_stars where shop_task_stars.shop_task_id = (select id from shop_tasks where shop_tasks.user_id = #{@current_user.id}))")
      # stars = stars.map do |star|
      #   {
      #     id: star.id,
      #     name: star.name,
      #     pic: star.picture_url,
      #     follower_count: 300,
      #     friendship: 0
      #   }
      # end
      # ret = {data: { stars: stars.as_json } }
      # success(ret)
      # fundings = Shop::Funding.active.select("id, title, date_format(created_at,'%y-%m-%d %h:%m:%s') as created_time, cover1").paginate(page: params[:page] || 1, per_page: params[:per] || 10).as_json
      # fundings = fundings.map{ |f| f.merge({participator: Shop::Funding.find_by(id: f['id']).participator.value, reword: "经验值同花费金额；O!元为花费金额的1%"}) } #@counter = Redis::Counter.new('funding_participator_#{f['id']}') @counter.increment @counter.value
      #
      # ret = {data: fundings}
      # success(ret)
    end

    desc "应援列表"
    params do
      requires :uid, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_fundings do
      fundings = Shop::Funding.active.select("id, title, date_format(created_at,'%y-%m-%d %h:%m:%s') as created_time, cover1").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10).as_json
      fundings = fundings.map{ |f| f.merge({participator: Shop::Funding.find_by(id: f['id']).participator.value, shop_category: "shop_fundings", reword: "经验值同花费金额；O!元为花费金额的1%"}) } #@counter = Redis::Counter.new('funding_participator_#{f['id']}') @counter.increment @counter.value

      ret = {data: {task: fundings, count: Shop::Funding.active.count}}
      success(ret)
    end

    desc "应援展示"
    params do
      requires :uid, type: Integer
      requires :funding_id, type: Integer
    end
    get :shop_funding_show do
      funding = Shop::Funding.find_by(id: params[:funding_id])
      star_list = funding.shop_task.core_stars.select("id", "published", "name").as_json
      if funding.user_id.present?
        user = Core::User.find_by(id: funding.user_id)
      else
        return fail(0, "该应援不存在发布者，请联系后台人员修改")
      end
      return fail(0, "该应援不存在") unless funding && funding.shop_task.is_available?
      funding = funding.as_json.merge({
        funding_total_fee: funding.funding_total_fee.to_f.round(2),
        result_describe: funding.result_describe,
        descripe_cover_url: funding.descripe_cover_url,
        cover1_pic: funding.cover_url(1),
        cover2_pic: funding.cover_url(2),
        cover3_pic: funding.cover_url(3),
        ext_infos: funding.ext_infos.select("shop_ext_infos.id, shop_ext_infos.title, shop_ext_infos.require"),
        shop_task_id: funding.shop_task.id,
        is_completed: (funding.shop_task.task_state["#{funding.class.to_s}:#{params[:uid]}"].to_i > 0),
        ticket_types: funding.ticket_types,
        stars: star_list,
        user_id: user.id,
        user_name: user.name,
        html_description: '',
        user_pic: user.picture_url,
        user_identity: user.identity,
        participator: funding.ticket_types.map{|a| a.participator.value.to_i}.sum,
        share_url: Rails.application.routes.url_helpers.shop_funding_url(params[:funding_id]),
        reward: "成功支持应援可获得 等值O!元和分享得 等值O!元"}).update({ "descripe2" => '', "star_list" => star_list, "end_at" => funding.end_at ? funding.end_at.to_s(:db) : '', "funding_progres" => funding.funding_progres})
      ret = { data: funding }
      success(ret)
    end

    desc "应援结果展示"
    params do
      requires :uid, type: Integer
      requires :funding_id, type: Integer
    end

    get :shop_funding_result_show do
      funding = Shop::Funding.find_by(id: params[:funding_id])
      return fail(0, '应援不存在') unless funding
      funding = {
        id: funding.id,
        result_describe: funding.result_describe,
      }
      success({data: {funding_result: funding}})
    end


    desc "任务排行榜"
    params do
      requires :uid, type: Integer
      requires :funding_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_funding_rank_list do
      funding = Shop::Funding.find_by(id: params[:funding_id])
      return fail(0, "该应援不存在") unless funding
      #此处排序要加索引
      ranking_list = Shop::OrderItem.by_id_and_type(params[:funding_id], "Shop::Funding")
        .joins("LEFT JOIN core_users users ON shop_order_items.user_id = users.id").select("shop_order_items.id, users.name, users.pic ,shop_order_items.payment").order("payment DESC").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10).as_json
      ranking_list.map{|r| r.merge({follower_count: 300, followable_count: 300})}
      ret = { data: {ranking_list: ranking_list} }
      success(ret)
    end

    desc "应援支持，购买订单"
    params do
      requires :uid, type: Integer
      requires :sum_fee, type: Float #0.00格式
      requires :fundings, type: Hash
      optional :address_id, type: Integer
    end
    post :shop_funding_orders_create do
      #"fundings"=>{"user_id"=>"购买人id", "ticket_type_id"=>"21", "info"=>"应援寄语", "quantity"=>"1"}
      app_version = Gem::Version.new(params[:app_version])
      shop_orders = [eval(params[:fundings])] #与web端一致
      order = shop_orders[0]
      ticket_type = Shop::TicketType.find_by(id: order[:ticket_type_id])
      array_status = ticket_type.created_order_options(order, order[:quantity].to_i, @current_user, can_equal=true, address_id=params[:address_id])
      return fail(0, array_status[1]) if !array_status[0] #判断是否能够购买
      shop_orders = shop_orders.map{|o| o.merge!({:split_memo => ""})} unless order[:split_memo].present?
      return fail(0, "商品价格发生变化，请重新下单") if (ticket_type.fee.to_f.round(2)*order[:quantity].to_i).to_f.round(2) != params[:sum_fee].to_f.round(2)
      order_no = UUID.generate(:compact)
      Redis.current.set("funding_order_by_#{order_no}", {order_no: "#{order_no}", address_id: params[:address_id].present? ? params[:address_id] : 0, status: 1, sum_fee: params[:sum_fee], shop_order: shop_orders, created_at: Time.now.to_s(:db) }.to_json )
      CheckoutFundingWorker.perform_async(shop_orders, params[:sum_fee].to_f, params[:address_id].present? ? params[:address_id] : 0, order_no, 0, params[:from_client], :checkout_funding)
      CoreLogger.info(logger_format(api: "shop_funding_orders_create", order_no: order_no))
      ret = { data: {order_no: order_no} }
      success(ret)
    end

  end
end
