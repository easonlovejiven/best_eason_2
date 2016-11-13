module V4
  class WelfareTaskApi < Grape::API

    format :json

    before do
      check_sign
    end

    desc "免费活动商品展示页面"
    params do
      optional :uid, type: Integer
      optional :type, type: String
      optional :welfare_id, type: Integer
    end
    get :welfare_product_show do
      product = eval(params[:type]).active.find_by(id: params[:welfare_id])
      return fail(0, "该商品不存在") unless product && product.shop_task.is_available?
      prices = product.ticket_types.map{|t| t.fee.to_f.round(2) }
      stars = product.shop_task.core_stars.select("core_stars.id, core_stars.name, core_stars.published").as_json
      ticket_types = product.ticket_types.map{|t| t.as_json.merge({participator: t.participator.value}) }

      product = product.as_json.merge({
        name: product.user.name,
        pic: product.user.picture_url,
        participator:product.ticket_types.map{|a| a.participator.value.to_i}.sum,
        descripe_cover_url: product.cover_pic,
        shop_task_id: product.shop_task.id,
        is_completed: (product.shop_task.task_state["#{product.class.to_s}:#{params[:uid]}"].to_i > 0),
        stars: stars,
        ticket_types: ticket_types.as_json,
        ext_infos: product.ext_infos.select("shop_ext_infos.id, shop_ext_infos.title, shop_ext_infos.require"),
        share_url: params[:type] == "Welfare::Event" ? Rails.application.routes.url_helpers.welfare_event_url(params[:welfare_id]) : Rails.application.routes.url_helpers.welfare_product_url(params[:welfare_id]),
        user_identity: product.user.identity,
      })

      ret = { data: product }
      success(ret)
    end

    desc "商品活动创建订单"
    params do
      requires :uid, type: Integer
      requires :type, type: String
      requires :welfare_id, type: Integer
      requires :ticket_type_id, type: Integer
      requires :infos, type: Integer
      requires :quantity, type: Integer
      requires :address_id, type: Integer
    end
    post :welfare_product_create do
      @current_user = Core::User.find_by(id: params[:uid])
      product = eval(params[:type]).find_by(id: params[:welfare_id])
      infos = eval(params[:infos])
      return fail(0, "免费商品必填地址！") if params[:type] == "Welfare::Product" && params[:address_id].blank?
      return fail(0, "该商品不存在") unless product
      fee = (Shop::TicketType.find_by(id: params[:ticket_type_id]).try(:fee) || 0) * (params[:quantity].to_i || 1)
      return fail(0, "O币不足!去做些任务把，再来享受我们的福利") unless @current_user.obi >= fee
      ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
      return fail(0, "商品价格发生变化！") if ticket_type.blank?
      return fail(0, "该商品已购买结束") if product.sale_end_at.present? && product.sale_end_at < Time.now
      return fail(0, "该商品购买未开始") if product.sale_end_at.present? && product.sale_start_at > Time.now
      return fail(0, "该款商品: #{ticket_type.task.title}, 每人限购#{ticket_type.each_limit}份, 您已经购买超额啦") if ticket_type.is_each_limit && (Core::Expen.where(user_id: @current_user.id, shop_ticket_type_id: ticket_type.id).map{|o| o.quantity}.sum + params[:quantity].to_i) > ticket_type.each_limit
      return fail(0, "该款商品当前购买人数已达上限，请稍后看看有没有取消订单的人再来吧。") if ticket_type.is_limit && ticket_type.participator.value.to_i >= ticket_type.ticket_limit
      #参与人数增加
      ticket_type.participator.incr(params[:quantity])
      ext_infos = []
      if infos
        infos = product.ext_infos.each_with_index do |v, i|
          return fail(0, "O妹暂不支持表情符号") if infos["#{v.title}"].present? && infos["#{v.title}"].judge_emoji
          return fail(0, "缺少必填的附加信息！") if infos["#{v.title}"].blank? && v.require == true
          ext_infos << {ext_info_id: v.id, value: infos["#{v.title}"]}
        end
      end
      Rails.logger.info "infos:----------------->#{ext_infos}"
      order_no = Digest::MD5.hexdigest("#{Time.now}_#{params[:welfare_id]}")
      Redis.current.set("welfare_order_by_#{order_no}", {order_no: "#{order_no}", sum_fee: ticket_type.fee.to_f.round(2), welfare_type: params[:type], welfare_id: params[:welfare_id], created_at: Time.now.to_s(:db) }.to_json )
      product.shop_task.payment_obi(@current_user, order_no: order_no, quantity: params[:quantity],fee: fee, ext_infos: ext_infos, shop_ticket_type_id: ticket_type.id, status: :complete, address_id: params[:address_id].to_i)
      CoreLogger.info(logger_format(api: "welfare_product_create", quantity: params[:quantity],fee: fee, ext_infos: ext_infos, shop_ticket_type_id: ticket_type.id, status: :complete, address_id: params[:address_id].to_i))
      if params[:from_client] == "iOS" && Gem::Version.new(params[:app_version]) > Gem::Version.new("3.26")
        success({data: {order_no: order_no}})
      elsif params[:from_client] == "Android" && Gem::Version.new(params[:app_version]) > Gem::Version.new("3.1.3")
        success({data: {order_no: order_no}})
      else
        success({data: true})
      end
    end

    desc "免费福利商品参与用户"
    params do
      requires :uid, type: Integer
      requires :shop_id, type: Integer
      requires :shop_category, type: String
    end
    get :get_welfare_users do
      page = params[:page].present? ? params[:page].to_i : 1
      per = params[:per_page].present? ? params[:per_page].to_i : 10
      case params[:shop_category]
      when 'Welfare::Product'
        task = Welfare::Product.find_by(id: params[:shop_id])
        return fail(0, "找不到该任务！！！") unless task.present?
        ret = Rails.cache.fetch("welfare_products_participators_shop_id_#{task.id}_#{task.class.name}_#{page}_#{per}", expires_in: 5.minutes) do
          @order = Core::Expen.includes([:user, :shop_task]).find_by_sql("SELECT o.amount, o.user_id, o.created_at FROM core_expens AS o WHERE o.resource_id = #{task.id} AND o.resource_type = '#{task.class.name}' ORDER BY o.amount DESC ").paginate(page: page, per_page: per)
          count = @order.total_entries
          @order = @order.map{|order|
            {
              user_id: order.user_id,
              user_name: order.user.name,
              user_pic: order.user.picture_url+"?imageMogr2/thumbnail/!30p",
              payment: order.amount.to_f.round(2),
              identity: order.user.identity,
              follow_count: order.user.follow_count,
              followers_count: order.user.followers_count,
              created_at: order.created_at.to_s(:db),
            }
          }
          [@order, count]
        end
      when 'Welfare::Event'
        task = Welfare::Event.find_by(id: params[:shop_id])
        return fail(0, "找不到该任务！！！") unless task.present?
        ret = Rails.cache.fetch("welfare_events_participators_shop_id_#{task.id}_#{task.class.name}_#{page}_#{per}", expires_in: 5.minutes) do
          @order = Core::Expen.includes([:user, :shop_task]).find_by_sql("SELECT o.amount, o.user_id, o.created_at FROM core_expens AS o WHERE o.resource_id = #{task.id} AND o.resource_type = '#{task.class.name}' ORDER BY o.amount DESC ").paginate(page: page, per_page: per)
          count = @order.total_entries
          @order = @order.map{|order|
            {
              user_id: order.user_id,
              user_name: order.user.name,
              user_pic: order.user.picture_url+"?imageMogr2/thumbnail/!30p",
              payment: order.amount.to_f.round(2),
              identity: order.user.identity,
              follow_count: order.user.follow_count,
              followers_count: order.user.followers_count,
              created_at: order.created_at.to_s(:db),
            }
          }
          [@order, count]
        end
      end
      success({data: {ret: ret[0], count: ret[1] }})
    end

    desc "免费福利商品订单列表"
    params do
      requires :uid, type: Integer
    end

    get :get_welfare_orders do
      @orders = Core::Expen.active.where(user_id: params[:uid]).where(resource_type: ["Welfare::Product", "Welfare::Event"]).order("created_at DESC")
      @orders = @orders.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      ret = @orders.includes([:resource, :ext_info_values, :ticket_type]).map{
        |order| order.as_json.merge!({
          category: "#{order.ticket_type.try(:category) || ""} | #{order.ticket_type.try(:second_category) || ""}",
          start_at: order.resource.sale_start_at,
          title: order.resource.title,
          address: order.resource.try(:address),
          pic: order.resource.cover_pic,
          receive_name: order.try(:user_name),
          receive_mobile: order.try(:phone),
          receive_address: order.try(:address),
          infos: order.ext_info_values.map{|e| "#{Shop::ExtInfo.find_by(id: e.ext_info_id).try(:title)}: #{e.value}" }
       }).update({"address" => order.resource.try(:address)}) }
       Rails.logger.info "ret:-------------------------->#{ret}"
      success({data: {orders: ret, count: @orders.total_entries }})
    end

    desc "图片福利展示列表"
    params do
      requires :uid, type: Integer
      requires :task_id, type: Integer
      requires :task_type, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :get_comments do
      comments = Shop::Comment.active
        .where(task_id: params[:task_id], task_type: params[:task_type], parent_id: 0)
        .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10).order("created_at DESC")
      count = comments.total_entries
      comments = comments.includes(:user).map do |c|
        {
          user_name: c.user.try(:name),
          user_pic: c.user && c.user.try(:picture_url)+"?imageMogr2/thumbnail/!30p",
          id: c.id,
          task_id: c.task_id,
          task_type: c.task_type,
          content: c.content,
          user_id: c.user_id,
          created_at: c.created_at,
          comments: Shop::Comment.where(task_id: params[:task_id], task_type: params[:task_type], parent_id: c.id).includes(:user).map do |d|
            {
              user_name: d.user.try(:name),
              user_pic: d.user && c.user.try(:picture_url)+"?imageMogr2/thumbnail/!30p",
              id: d.id,
              task_id: d.task_id,
              task_type: d.task_type,
              content: d.content,
              user_id: d.user_id,
              created_at: d.created_at,

            }
          end
        }
      end
      success({data: {comments: comments, count: count}})
    end

    desc "图片福利创建"
    params do
      requires :uid, type: Integer
      requires :content, type: String
      optional :parent_id, type: Integer
      requires :task_id, type: Integer
      requires :task_type, type: String
    end
    post :create_comments do
      status = ActiveRecord::Base.transaction do
        @comment = Shop::Comment.new({user_id: params[:uid], content: params[:content], task_id: params[:task_id], task_type: params[:task_type], parent_id: (params[:parent_id] && params[:parent_id] != 0) ? params[:parent_id] : 0})
        @comment.save
      end
      if status
        AwardWorker.perform_async(params[:uid], @comment.id, @comment.class.name, 2, 1, 'self', :award)
        CoreLogger.info(logger_format(api: "create_comments", comment_id: @comment.try(:id)))
        success({data: {task_id: params[:task_id]}})
      else
        fail_msg(0, '创建图片福利失败')
      end
    end

    desc "查看免费订单是否存在"
    params do
      requires :order_no, type: String
    end
    get :search_free_welfare_order do
      @redis_order = Redis.current.get("welfare_order_by_#{params[:order_no]}")
      return fail(0, "该订单不存在") unless @redis_order.present?
      @order = eval(@redis_order)
      # 0 排队中 1 排队成功 2 排队失败
      if @order[:status] == 2
        success({data: {is_true: 1}})
      elsif @order[:error].present?
        success({data: {is_true: 2}})
      else
        success({data: {is_true: 0}})
      end
    end


  end
end
