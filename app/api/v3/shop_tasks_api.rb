# encoding:utf-8
module V3
  class ShopTasksApi < Grape::API
    format :json

    before do
      check_sign
    end

    desc "微信支付给android返回参数"
    params do
      requires :uid, type: Integer
      requires :order_no, type: String
      requires :shop_category, type: String
      requires :spbill_create_ip, type: String
    end

    post :make_wx_pay_params do
      @timestamp = Time.now.to_i
      @nonce_str = SecureRandom.hex(16)
      if params[:shop_category] == 'Shop::Funding'
        order = Shop::FundingOrder.find_by(order_no: params[:order_no])
        return fail(0, "找不到该订单") unless order
        product = order.owhat_product
        xml = wxpay_v3_xml(@nonce_str, product.title, order.order_no, (order.payment.to_f.round(2) * 100).to_i,  "#{Rails.application.routes.default_url_options[:host]}/v3/shop_funding_wx_back", params[:spbill_create_ip])
        r = RestClient.post 'https://api.mch.weixin.qq.com/pay/unifiedorder', xml , {:content_type => :xml}
        return_hash = Hash.from_xml(r)
        return fail(0, return_hash['xml']['return_msg']) if return_hash['xml']['return_code'] == 'FAIL'
        prepay_id = return_hash['xml']['prepay_id']
        return fail(0, "生成不了prepay_id") unless order unless prepay_id
        pay_sign = return_wxpay_sign "#{@timestamp}", "#{@nonce_str}" , "#{prepay_id}"
        ret = {prepayid: prepay_id,
               noncestr: @nonce_str,
               timestamp: @timestamp,
               partnerid: return_hash['xml']['mch_id'],
               package: 'Sign=WXPay',
               sign: pay_sign,
               appid: return_hash['xml']['appid'],
               total_fee: (order.payment.to_f.round(2) * 100).to_i,
               order_no: order.order_no,
               notifi_url: "#{Rails.application.routes.default_url_options[:host]}/v3/shop_funding_wx_back",
               body: product.title
        }
        Rails.logger.info "---------------------------11111111111111111111111111111111ret: #{ret}"
        success({data: {wx_params: ret}})
      else
        order = Shop::Order.find_by(order_no: params[:order_no])
        return fail(0, "找不到该订单") unless order
        body = order.order_items.map{ |o| Shop::TicketType.find(o[:shop_ticket_type_id]).task.title }.join(', ') || 'Owhat 应援订单支付'
        xml = wxpay_v3_xml(@nonce_str, body, order.order_no, (order.total_fee.to_f.round(2) * 100).to_i,  "#{Rails.application.routes.default_url_options[:host]}/v3/shop_product_wx_back", params[:spbill_create_ip])
        r = RestClient.post 'https://api.mch.weixin.qq.com/pay/unifiedorder', xml , {:content_type => :xml}
        return_hash = Hash.from_xml(r)
        return fail(0, return_hash['xml']['return_msg']) if return_hash['xml']['return_code'] == 'FAIL'
        prepay_id = return_hash['xml']['prepay_id']
        return fail(0, "生成不了prepay_id") unless order unless prepay_id
        pay_sign = return_wxpay_sign "#{@timestamp}", "#{@nonce_str}" , "#{prepay_id}"
        ret = {prepayid: prepay_id,
               noncestr: @nonce_str,
               timestamp: @timestamp,
               partnerid: return_hash['xml']['mch_id'],
               package: 'Sign=WXPay',
               sign: pay_sign,
               appid: return_hash['xml']['appid'],
               total_fee: (order.total_fee.to_f.round(2) * 100).to_i,
               order_no: order.order_no,
               notifi_url: "#{Rails.application.routes.default_url_options[:host]}/v3/shop_product_wx_back",
               body: body
        }
        Rails.logger.info "---------------------------11111111111111111111111111111111ret: #{ret}"
        success({data: {wx_params: ret}})
      end
    end

    desc "微信订单查询接口"
    params do
      requires :order_no, type: Integer
      optional :from, type: Integer
      optional :shop_category, type: Integer
    end
    get :find_wx_order_status do
      status, result = Shop::OrderHelper.search_wxpay_status params[:order_no], params[:shop_category], params[:form]
      if status == 'success'
        success({data: result})
      else
        fail(0, result)
      end
    end


    desc "分期乐支付"
    params do
      requires :order_no, type: Integer
      optional :category, type: String
    end
    post :fenqile_pay do
      order = if params[:category] == 'Shop::Funding'
        Shop::FundingOrder.find_by(order_no: params[:order_no])
      else
        Shop::Order.find_by(order_no: params[:order_no])
      end
      return fail(0, "找不到该订单") unless order

      options = {
        amount: params[:category] == 'Shop::Funding' ? (order.payment*100).to_i : (order.total_fee*100).to_i,
        out_trade_no: order.order_no,
        partner_id: Rails.application.secrets.fenqile["appid"],
        notify_url: "#{Rails.application.routes.default_url_options[:host]}/shop/orders/#{order.order_no}/fenqile_success?source=notify", #Rails.application.routes.url_helpers.success_shop_order_url(params_hash[:order_no]),
        return_url: "#{Rails.application.routes.default_url_options[:host]}/shop/orders/#{order.order_no}/fenqile_success",
        subject: order.order_items.map{ |o| Shop::TicketType.find(o[:shop_ticket_type_id]).task.title }.join(', ') || 'Owhat 订单支付',
        client_ip: env["REMOTE_ADDR"],
        c_merch_id: 1,
        payment_type: 2,
      }
      action = "http://mapi.fenqile.com/merchpay/pay"
      sign = Digest::MD5.hexdigest(options.sort.map{|k,v|"#{k}=#{v}"}.join("&")+ "&key=#{Rails.application.secrets.fenqile["key"]}")
      options.merge!(sign: sign)
      resp = eval HTTParty.post(action, body: options.to_json).body
      if resp[:result] == 0
        CoreLogger.info(logger_format(api: "fenqile_pay", order_id: order.try(:id)))
        success(data: { url: resp[:url] })
      else
        Rails.logger.info(resp)
        fail(0, "操作失败，请稍后再试")
      end
    end

    desc "商品、活动列表"
    params do
      requires :uid, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_products do
      products = Shop::Product.find_by_sql("SELECT `p`.id, `p`.title, date_format(`p`.created_at,'%y-%m-%d %h:%m:%s') as created_time, `p`.cover1, `p`.shop_category FROM `shop_products` AS `p` UNION ALL
                                 SELECT `e`.id, `e`.title, date_format(`e`.created_at,'%y-%m-%d %h:%m:%s') as created_time, `e`.cover1, `e`.shop_category FROM `shop_events` AS `e` LIMIT #{params_hash[:per_page] || 20} OFFSET #{params_hash[:page] || 1};").as_json
      products = products.map{ |f| f.merge({participator: f['shop_category'] == "shop_products" ? Shop::Product.find_by(id: f['id']).participator.value : Shop::Event.find_by(id: f['id']).participator.value }) } #@counter = Redis::Counter.new('product_participator_#{f['id']}') @counter.increment @counter.value

      ret = {data: {task: products, count: Shop::Product.active.count+Shop::Event.active.count}}
      success(ret)
    end

    desc "商品、活动展示"
    params do
      requires :uid, type: Integer
      requires :type, type: String
      requires :id, type: Integer
    end
    get :shop_task_show do
      if params[:type] == "shop_products"
        product = Shop::Product.find_by(id: params[:id])
        return fail(0, "该商品不存在") unless product && product.shop_task.is_available?
        prices = product.ticket_types.map{|t| t.fee.to_f.round(2) }
        max_price = prices.max
        min_price = prices.min
        stars = product.shop_task.core_stars.select("core_stars.id, core_stars.name, core_stars.published").as_json
        ticket_types = product.ticket_types.map{|t| t.as_json.merge({participator: t.participator.value}) }

        product = product.as_json.merge({
          name: product.user.name,
          pic: product.user.picture_url,
          descripe_cover_url: product.descripe_cover_url,
          cover1_pic: product.cover_url(1),
          cover2_pic: product.cover_url(2),
          cover3_pic: product.cover_url(3),
          shop_task_id: product.shop_task.id,
          is_completed: (product.shop_task.task_state["#{product.class.to_s}:#{params[:uid]}"].to_i > 0),
          max_price: max_price.to_f.round(2),
          min_price: min_price.to_f.round(2),
          participator: product.shop_task.participants,#参与人数
          total_participator: product.shop_task.participator,#售卖份数
          reward: "成功支持商品可获得O!元奖励和分享得O!元奖励",
          stars: stars,
          ticket_types: ticket_types.as_json,
          ext_infos: product.ext_infos.select("shop_ext_infos.id, shop_ext_infos.title, shop_ext_infos.require"),
          share_url: Rails.application.routes.url_helpers.shop_product_url(params[:id]),
          user_identity: product.user.identity,
          html_description: ''
        }).update({"descripe2" => ''})

        ret = { data: product }
      else
        event = Shop::Event.find_by(id: params[:id])
        return fail(0, "该商品不存在") unless event && event.shop_task.is_available?
        stars = event.shop_task.core_stars.select("core_stars.id, core_stars.name, core_stars.published").as_json
        prices = event.ticket_types.map{|t| t.fee.to_f.round(2) }
        max_price = prices.max
        min_price = prices.min
        ticket_types = event.ticket_types.map{|t| t.as_json.merge({participator: t.participator.value}) }

        event = event.as_json.merge({
          name: event.user.name,
          pic: event.user.picture_url,
          descripe_cover_url: event.descripe_cover_url,
          cover1_pic: event.cover_url(1),
          cover2_pic: event.cover_url(2),
          cover3_pic: event.cover_url(3),
          shop_task_id: event.shop_task.id,
          is_completed: (event.shop_task.task_state["#{event.class.to_s}:#{params[:uid]}"].to_i > 0),
          max_price: max_price.to_f.round(2),
          min_price: min_price.to_f.round(2),
          participator: event.shop_task.participants,
          total_participator: event.shop_task.participator,
          reward: "成功支持商品可获得O!元奖励和分享得O!元奖励",
          stars: stars,
          ticket_types: ticket_types.as_json,
          ext_infos: event.ext_infos.select("shop_ext_infos.id, shop_ext_infos.title, shop_ext_infos.require"),
          share_url: Rails.application.routes.url_helpers.shop_event_url(params[:id]),
          user_identity: event.user.identity,
          html_description: ''
        }).update({"descripe2" => ''})
        ret = { data: event }
      end
      success(ret)
    end

    desc "商品、活动、应援价格展示页面"
    params do
      requires :uid, type: Integer
      requires :type, type: String
      requires :id, type: Integer
    end
    get :shop_ticket_type_show do
      product = eval(params[:type]).find_by(id: params[:id])

      return fail(0, "该商品不存在") unless product && product.shop_task.is_available?
      ticket_types = product.ticket_types.map{|t| t.as_json.merge({participator: t.participator.value}) }
      ret = {
        title: product.title,
        cover1_pic: params[:type].match(/Welfare/) ? product.cover_pic : product.cover_url(1),
        ticket_types: ticket_types.as_json,
        ext_infos: product.ext_infos.select("shop_ext_infos.id, shop_ext_infos.title, shop_ext_infos.require"),
      }

      success({data: ret})
    end

    desc "确认购买时判断购买是否超额"
    params do
      requires :ticket_type_id, type: Integer
      requires :uid, type: Integer
      requires :shop_type, type: String
    end

    get :get_can_purchase_limit do
      ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
      return fail(0, "商品信息已发生变化，请返回列表重新购买") if ticket_type.blank?
      if params[:shop_type] == "shop_funding"
        paid_quantity = Shop::FundingOrder.where(user_id: params[:uid], status: 2, shop_ticket_type_id: params[:ticket_type_id]).map{|o| o.quantity}.sum
      else
        paid_quantity = Shop::OrderItem.where(user_id: params[:uid], status: 2, shop_ticket_type_id: params[:ticket_type_id]).map{|o| o.quantity}.sum
      end
      quantity = ticket_type.can_purchase_limit paid_quantity
      success({data: {quantity: quantity}})
    end


    desc "商品活动结算运费获取"
    params do
      requires :ticket_types_attributes, type: String
      requires :user_id, type: Integer
      requires :address_id, type: Integer
    end

    get :get_freight_fee do
      #传入参数{"O星人UdEXVmF4"=>[{"id"=>"24", "quantity"=>"1"}, {"id"=>"16", "quantity"=>"1"}, {"id"=>"20", "quantity"=>"1"}]}
      ticket_types = eval(params[:ticket_types_attributes])
      sum_freight_fee, products_hash = {}, {}
      address = Core::Address.find_by(id: params[:address_id])
      return fail(0, "地址不存在！请新增地址")unless address.present?
      ticket_types.each do |user_name, shop_array|
        shop_array.each do |t|
          type_id = t['id'] || t[:id]
          quantity = t['quantity'] || t[:quantity]
          type = Shop::TicketType.find_by(id: type_id.to_i)
          task_id = "#{type.task_id}"+"#{type.task_type}"
          if products_hash.has_key?(task_id)
            products_hash.update({ task_id => products_hash[task_id].merge!({ type_id.to_i => quantity.to_i }) })
          else
            products_hash.merge!({
              task_id => { type_id.to_i => quantity.to_i }
            })
          end
        end
        get_freight_fee = Shop::OrderItem.calculate_freight_fee(address.try(:id), products_hash, true)
        #return fail(0, "该地址不支持购买") if get_freight_fee[0] == '该地址不支持购买'
        return fail(0, "邮费价格结算错误，请重新结算(可能您的地址编辑出现问题， 请将地址必填项填好。)") if get_freight_fee[0] == false
        all_freight_fee = get_freight_fee[1]
        freight_fee_array = shop_array.map{ |t| type_id = t['id'] || t[:id] and t.merge!({'freight_fee' => all_freight_fee.fetch(type_id.to_i) }) }
        sum_freight_fee.merge!({"#{user_name}" => freight_fee_array})
      end
      success({data: sum_freight_fee})
    end

    desc "加入购物车"
    params do
      requires :uid, type: Integer
      requires :ticket_type_id, type: Integer
      requires :quantity, type: Integer
      requires :shop_category, type: String
      requires :shop_task_id, type: Integer
      optional :split_memo, type: String
    end
    #"ticket_type_id"=>"24", "quantity"=>"1", "info0"=>"infos", "shop_category"=>"shop_events", "shop_task_id"=>"45"
    post :add_cart do
      shop_category = params[:shop_category]
      case shop_category
      when "shop_events"
        @task = Shop::Event.find_by(id: params[:shop_task_id])
      when "shop_products"
        @task = Shop::Product.find_by(id: params[:shop_task_id])
      when "shop_fundings"
        @task = Shop::Funding.find_by(id: params[:shop_task_id])
      end
      @ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
      params['info0'].present? ? ext_infos = params[:info0].to_s.strip_emoji : ext_infos = ""
      params['split_memo'].present? ? split_memo = params[:split_memo].to_s.strip_emoji : split_memo = ""
      cart_hash = Shop::Cart.add_cart(@current_user, @ticket_type, @task, {params: params, ext_infos: ext_infos, split_memo: split_memo})
      h = {}
      cart_hash.each{ |key, c| name = Core::User.find(key).name and h.merge!(name => eval(c)) }
      ret = {data: h}
      CoreLogger.info(logger_format(api: "add_cart", params: params))
      success(ret)
    end

    desc "ios编辑购物车详情页面"
    params do
      requires :uid, type: Integer
      optional :ticket_type_id, type: Integer
      requires :pre_ticket_type_id, type: Integer #原有价格
      requires :quantity, type: Integer
      requires :shop_category, type: String
      requires :shop_task_id, type: Integer
    end
    post :edit_cart_details do
      Rails.cache.delete("my_carts_by_#{params[:uid]}")
      current_user = Core::User.find_by(id: params[:uid])
      shop_category = params[:shop_category]
      case shop_category
      when "shop_events"
        @task = Shop::Event.find_by(id: params[:shop_task_id])
      when "shop_products"
        @task = Shop::Product.find_by(id: params[:shop_task_id])
      when "shop_fundings"
        @task = Shop::Funding.find_by(id: params[:shop_task_id])
      end
      # params['info0'].present? ? ext_infos = params[:info0] : ext_infos = "" #附加信息
      if params['info0'].present?
        ext_infos = params[:info0].to_s.gsub(/[\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E7}-\u{1F1EC}\u{1F1EE}-\u{1F1F0}\u{1F1F3}\u{1F1F5}\u{1F1F7}-\u{1F1FA}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F320}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}]/,'')
      else
        ext_infos = ""
      end
      if params['split_memo'].present?
        split_memo = params[:split_memo].to_s.gsub(/[\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E7}-\u{1F1EC}\u{1F1EE}-\u{1F1F0}\u{1F1F3}\u{1F1F5}\u{1F1F7}-\u{1F1FA}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F320}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}]/,'')
      else
        split_memo = ""
      end

      cart = current_user.cart.my_carts
      cart_hash = current_user.cart.my_carts.all

      if params[:ticket_type_id]
        #如果新的购物车商品价格出来
        ## 删掉原有价格
        pre_ticket_type = Shop::TicketType.find_by(id: params[:pre_ticket_type_id])
        if pre_ticket_type.present?
          pre_user_id = pre_ticket_type.task.user.id
          if cart_hash.has_key?("#{pre_user_id}")
            products_hash = eval(cart_hash["#{pre_user_id}"])
            if products_hash.has_key?("#{pre_ticket_type.id}")
              products_hash.delete("#{pre_ticket_type.id}")
              if products_hash.size == 0
                cart.delete("#{pre_user_id}")
                cart_hash = cart
              else
                cart["#{pre_user_id}"] = products_hash
                cart_hash.update("#{pre_user_id}" => cart["#{pre_user_id}"])
              end
            else
              cart.delete("#{pre_user_id}")
              cart_hash = cart
            end
          end
        else
          cart_hash.each do |k, v|
            products_hash = eval(v)
            next unless products_hash.has_key?("#{params[:pre_ticket_type_id]}")
            if products_hash.has_key?("#{params[:pre_ticket_type_id]}")
              products_hash.delete("#{params[:pre_ticket_type_id]}")
              if products_hash.size == 0
                cart.delete("#{k}")
              else
                cart["#{k}"] = products_hash
                cart_hash.update("#{k}" => cart["#{k}"])
              end
            end
          end
        end

        ### 增加新的商品价格对应商品进来
        @ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
        if cart_hash.has_key?("#{@task.user_id}")
          # 购物车中有该商家的商品
          products_hash = eval(cart_hash["#{@task.user_id}"])

          if products_hash.has_key?("#{params[:ticket_type_id]}")
            # 购物车中有同样的商品
            quantity = products_hash["#{params[:ticket_type_id]}"]["quantity"].to_i + params[:quantity].to_i
            # 更新购物车
            cart["#{@task.user_id}"] = products_hash.update({"#{params[:ticket_type_id]}" => products_hash["#{params[:ticket_type_id]}"].update({"quantity" => quantity, "split_memo" => split_memo, "infos" => ext_infos, "total_fee" => @ticket_type.fee.to_f.round(2) * quantity }) })
            cart_hash.update("#{@task.user_id}" => cart["#{@task.user_id}"])
          else
            # 购物车中有该商家但是没有该商品直接添加
            cart["#{@task.user_id}"] = products_hash.merge!({ "#{params[:ticket_type_id]}" => { "each_limit" => @ticket_type.is_each_limit ? @ticket_type.each_limit : 99999999, "shop_id" => @task.id, "shop_category" => @task.shop_category,  "cover1" => "#{@task.cover_pic}?imageMogr2/auto-orient/thumbnail/!120x120r/gravity/Center/crop/120x120", "title" => @task.title, "start_at" => @task.start_at.to_s(:db),  "end_at" => @task.end_at.to_s(:db), "sale_start_at" => @task.sale_start_at.to_s(:db), "sale_end_at" => @task.sale_end_at.to_s(:db), "address" => @task.address, "category" => @ticket_type.category, "fee" => @ticket_type.fee.to_f.round(2), "quantity" => params["quantity"], "total_fee" => @ticket_type.fee.to_f.round(2) * params["quantity"].to_i, "split_memo" => split_memo, "infos" => ext_infos } })
            cart_hash.update("#{@task.user_id}" => cart["#{@task.user_id}"])
          end
        else
          cart["#{@task.user_id}"] = { "#{params[:ticket_type_id]}" => { "each_limit" => @ticket_type.is_each_limit ? @ticket_type.each_limit : 99999999, "shop_id" => @task.id, "shop_category" => @task.shop_category, "cover1" => "#{@task.cover_pic}?imageMogr2/auto-orient/thumbnail/!120x120r/gravity/Center/crop/120x120", "title" => @task.title, "start_at" => @task.start_at.to_s(:db),  "end_at" => @task.end_at.to_s(:db), "sale_start_at" => @task.sale_start_at.to_s(:db), "sale_end_at" => @task.sale_end_at.to_s(:db), "address" => @task.address, "category" => @ticket_type.category, "fee" => @ticket_type.fee.to_f.round(2), "quantity" => params["quantity"], "total_fee" => @ticket_type.fee.to_f.round(2) * params["quantity"].to_i, "split_memo" => split_memo, "infos" => ext_infos } }
          cart_hash.update("#{@task.user_id}" => cart["#{@task.user_id}"])
        end

      else
        @ticket_type = Shop::TicketType.find_by(id: params[:pre_ticket_type_id])
        #如果价格类型没变
        products_hash = eval(cart_hash["#{@task.user_id}"])
        cart["#{@task.user_id}"] = products_hash.update({"#{params[:pre_ticket_type_id]}" => products_hash["#{params[:pre_ticket_type_id]}"].update({"quantity" => params[:quantity], "split_memo" => split_memo, "infos" => ext_infos, "total_fee" => @ticket_type.fee.to_f.round(2) * params[:quantity] }) })
        cart_hash.update("#{@task.user_id}" => cart_hash["#{@task.user_id}"])
      end

      h = {}
      cart_hash.each{ |key, c| name = Core::User.find(key).name and h.merge!(name => c) }
      ret = {data: h}
      success(ret)
    end

    desc "我的购物车"
    params do
      requires :uid, type: Integer
    end

    get :get_my_carts do
      # h = Rails.cache.fetch("my_carts_by_#{params[:uid]}") do
        cart_hash = Shop::Cart.find_by(uid: params[:uid]).my_carts.all
        c_hash = {}
        cart_hash.each{ |key, c| name = Core::User.find(key).name and
         c_hash.merge!(name => eval(c).each{|type, v|
           t = Shop::TicketType.find_by(id: type) and
           order_size = Shop::OrderItem.where(user_id: params[:uid], shop_ticket_type_id: type, status: 2).map(&:quantity).sum and
           limit = t.can_purchase_limit(order_size) and
           v.merge!(limit: limit) }
         )
        }
        c_hash
      # end
      ret = {data: c_hash}
      success(ret)
    end

    desc "删除购物车"
    params do
      optional :ticket_type_id, type: Integer
      optional :quantity, type: Integer
      optional :status, type: String
      requires :uid, type: Integer
    end

    delete :delete_cart do
      unless params[:status] == 'all'
        ticket_type = Shop::TicketType.find_by(id: params[:ticket_type_id])
        if ticket_type.present?
          Shop::Cart.delete_cart(@current_user, ticket_type.task.user.id, params)
        else
          Shop::Cart.delete_cart_by_ticket_type_id(@current_user, params[:ticket_type_id].to_i)
        end
      else
        cart = current_user.cart.my_carts.clear
      end
      ret = {data: {ticket_type_id: params[:ticket_type_id]} }
      CoreLogger.info(logger_format(api: "delete_cart", params: params))
      success(ret)
    end

    desc "编辑购物车"
    params do
      requires :ticket_types_attributes, type: String
      requires :uid, type: Integer
    end

    post :edit_cart do
      Rails.cache.delete("my_carts_by_#{params[:uid]}")
      user = Core::User.find_by(id: params[:uid])
      cart = user.cart.my_carts
      cart_hash = user.cart.my_carts.all
      ticket_types = eval(params[:ticket_types_attributes])
      ticket_types.each do |ticket_type, quantity|
        t = Shop::TicketType.find_by(id: ticket_type)
        if t.present?
          user_id = t.task.user.id
          if cart_hash.has_key?("#{user_id}")
            products_hash = eval(cart_hash["#{user_id}"])
            if products_hash.has_key?("#{ticket_type}")
              if quantity.to_i == 0 || quantity.to_i < 0
                products_hash.delete("#{ticket_type}")
                if products_hash.size == 0
                  cart.delete("#{user_id}")
                else
                  cart["#{user_id}"] = products_hash
                  cart_hash.update("#{user_id}" => cart["#{user_id}"])
                end
              else
                cart["#{user_id}"] = products_hash.update ({"#{ticket_type}" => products_hash["#{ticket_type}"].update({"quantity" => quantity }) })
                cart_hash.update("#{user_id}" => cart["#{user_id}"])
              end
            end
          end
        else
          Shop::Cart.delete_cart_by_ticket_type_id(@current_user, ticket_type)
        end

      end
      CoreLogger.info(logger_format(api: "edit_cart", params: params))
      ret = {data: true}
      success(ret)
    end

    desc "商品支持，购买订单, 立即购买, 购物车结算"
    params do
      requires :uid, type: Integer
      requires :address_id, type: Integer
      requires :shop_order, type: Array
      requires :sum_fee, type: Float
      requires :freight_fee, type: Float
    end
    #{"address_id"=>"12", "shop_order"=>[{"user_id"=>"1", "ticket_type_id"=>"16", "info"=>"qq: 287715007  微博id: sun528  ", "quantity"=>"1", 'freight_fee' => 0.01}, {"user_id"=>"1", "ticket_type_id"=>"20", "info"=>"qq: 287715007  微博id: sun528  ", "quantity"=>"1"}, {"user_id"=>"1", "ticket_type_id"=>"24", "info"=>"微博id: \"sssss\"  ", "quantity"=>"1"}], "sum_fee"=>"550.04", "freight_fee"=>"0.01", "shop_category"=>""}
    post :shop_product_orders_create do
      return fail(0, "为了爱豆们，先创建个地址吧！") unless params[:address_id].present?
      order_no = UUID.generate(:compact)
      shop_order = eval(params[:shop_order])
      return fail(0, "很抱歉ios暂时不支持同时购买多个商品！") if params[:from_client] == "iOS" && shop_order.size > 1 && Gem::Version.new(params[:app_version]) < Gem::Version.new("3.23")
      total_fee = 0
      all_ticket_types = []
      shop_order = shop_order.map do |order|
        ticket_type = Shop::TicketType.find_by(id: order[:ticket_type_id])
        return fail(0, "价格信息发生变化，请重新购买") unless ticket_type.present?
        total_fee += ticket_type.fee.to_f.round(2)*order[:quantity].to_i
        array_status = ticket_type.created_order_options(order, order[:quantity], @current_user, can_equal=true, address_id=params[:address_id])
        return fail(0, array_status[1]) if !array_status[0] #判断是否能够购买
        Shop::Cart.delete_cart(@current_user, ticket_type.task.user.id, order)
        all_ticket_types << [ticket_type, order[:quantity]]
        order[:split_memo].present? ? order : order.merge!({:split_memo => ""})
      end
      return fail(0, "商品价格发生变化，请重新下单") if (total_fee.to_f.round(2) + params[:freight_fee].to_f.round(2)).to_f.round(2) != params[:sum_fee].to_f.round(2)
      Redis.current.set("order_by_#{order_no}", {order_no: "#{order_no}", address_id: params[:address_id], status: 1, sum_fee: params[:sum_fee], shop_order: shop_order, created_at: Time.now.to_s(:db) }.to_json )
      CheckoutCartsWorker.perform_async(shop_order, params[:sum_fee].to_f, params[:address_id], order_no, params[:freight_fee], params[:from_client], :checkout_carts)
      #参与人数增加
      all_ticket_types.map{|t,count| t.participator.incr(count)}
      CoreLogger.info(logger_format(api: "shop_product_orders_create", params: params))
      success({data: {order_no: order_no}})
    end

    desc "查看免费订单是否存在"
    params do
      requires :order_no, type: String
    end
    get :search_free_order do
      @redis_order = Redis.current.get("order_by_#{params[:order_no]}")
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

    desc "查询商品购买订单是否存在"
    params do
      requires :order_category, type: String
      requires :order_no, type: String
    end

    get :search_shop_order do
      if params[:order_category] == "owhat_product"
        @order = Shop::Order.find_by(order_no: params[:order_no])
        return fail(0, "订单正在创建中......,稍后进行选择结算方式，如果长时间不能进行支付，请去掉留言中表情和确认地址已经填好！") unless @order.present?
        return fail(0, "订单已经支付过了") if @order.status == 'paid'
        return fail(0, "订单已过期，请重新下单") if @order.status == 'deleted'
        return fail(0, "订单已取消") if @order.status == 'canceled'
        return fail(0, "订单已过期，请重新下单") if Time.now > @order.expired_at
        return fail(0, "订单已经支付过了") unless @order.can_order_pay_and_cancel?
        return fail(0, "很抱歉ios暂时不支持同时购买多个商品！") if params[:from_client] == "iOS" && @order.order_items.size > 1 && Gem::Version.new(params[:app_version]) < Gem::Version.new("3.23")
        @order.order_items.each do |item|
          ticket_type = item.ticket_type
          array_status = ticket_type.created_order_options(item, item.quantity, @current_user, can_equal=false, address_id=params[:address_id])
          return fail(0, array_status[1]) if !array_status[0] #判断是否能够购买
        end
        get_freight_fee = Shop::OrderItem.calculate_freight_fee(@order.address_id, @order.get_freight_fee_hash)
        return fail(0, "该地址不支持购买") if get_freight_fee[0] == '该地址不支持购买'
        return fail(0, "邮费价格结算错误，请重新结算(可能您的地址编辑出现问题， 请将地址必填项填好。)") if get_freight_fee[0] == false || @order.freight_fee != get_freight_fee[1].values.sum
        obi = @order.total_fee.to_f.round(2)*0.1 < 1 ? 1 : (@order.total_fee.to_f.round(2)*0.1).to_i
      else
        @order = Shop::FundingOrder.find_by(order_no: params[:order_no])
        return fail(0, "订单好像没创建成功，请稍后再试。") unless @order.present?
        return fail(0, "订单已经支付过了") if @order.status == 'paid'
        return fail(0, "订单已过期，请重新下单") if @order.status == 'deleted'
        return fail(0, "订单已取消") if @order.status == 'canceled'
        return fail(0, "订单已经支付过了") unless @order.can_order_pay_and_cancel?
        ticket_type = @order.ticket_type
        array_status = ticket_type.created_order_options(@order, @order.quantity, @current_user, can_equal=false, address_id=params[:address_id])
        return fail(0, array_status[1]) if !array_status[0] #判断是否能够购买
        obi = @order.payment.to_f.round(2)*0.1 < 1 ? 1 : (@order.payment.to_f.round(2))*0.1.to_i
      end
      if @order.present?
        @order.update(platform: params[:from_client]) unless @order.platform == params[:from_client]
        if params[:order_category] == "owhat_product"
          success({data: {status: true, obi: obi, expired_at: @order.expired_at.to_s(:db)}})
        else
          success({data: {status: true, obi: obi, expired_at: (@order.created_at + 120.minutes).to_s(:db)}})
        end
      else
        success({data: {status: false}})
      end
    end

    desc "认证用户发布商品/活动任务"
    params do
      requires :shop_task_type, type: String, desc: "判断传入是商品还是活动"
      requires :title, type: String
      requires :description, type: String
      requires :descripe_key, type: String
      requires :descripe2, type: String
      requires :key1, type: String
      requires :key2, type: String
      requires :key3, type: String
      requires :start_at, type: DateTime
      requires :end_at, type: DateTime
      requires :sale_start_at, type: DateTime
      requires :sale_end_at, type: DateTime
      requires :address, type: String
      requires :mobile, type: String
      requires :uid, type: Integer
      requires :is_share, type: Boolean
      requires :is_need_express, type: Boolean
      requires :freight_template_id, type: Integer, desc: "运费模板id"
      requires :star_list, type: String, desc: "关联明星"
      optional :ext_infos_attributes, type: Array do
        requires :title, type: String
        requires :task_id, type: Integer, desc: "多态关联商品和活动"
        requires :task_type, type: String, desc: "多态关联商品和活动"
        requires :require, type: Boolean
      end
      optional :ticket_types_attributes, type: Array do
        requires :category_id, type: Integer
        requires :original_fee, type: BigDecimal
        requires :fee, type: BigDecimal
        requires :ticket_limit, type: Integer, desc: '限购数量'
        requires :is_limit, type: Boolean
        requires :is_each_limit, type: Boolean, desc: "是否每人限购"
        requires :each_limit, type: Integer, desc: "每人限购数量"
      end
    end
    post :publish_task do
      status = ActiveRecord::Base.transaction do
        if params_hash[:shop_task_type] == "Shop::Event"
          product = Shop::Event.new(params_hash.reject{ |k,v| k == 'shop_task_type' })
        else
          product = Shop::Product.new(params_hash.reject{ |k,v| k == 'shop_task_type' })
        end
        product.save
        product.update_shop_task_star
      end
      if status
        CoreLogger.info(logger_format(api: "publish_task", shop_task_type: params_hash[:shop_task_type], product_id: product.try(:id) ))
        success({data: true})
      else
        fail(0, "创建失败")
      end
    end

    desc "查看直播"
    params do
      requires :uid, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_subjects do
      subjects = Shop::Task.active.where(shop_type: 'Shop::Subject' ).select("id, guide, title, date_format(created_at,'%y-%m-%d %h:%m:%s') as created_time, description, pic").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10).as_json
      ret = {data: { subjects: subjects, count: Shop::Subject.active.count }}
      success(ret)
    end

    desc "查看直播详情"
    params do
      requires :uid, type: Integer
      requires :task_id, type: Integer
    end
    get :shop_subjects_show do
      subject = Shop::Subject.where(id: params[:task_id]).first
      return fail(0, "该直播不存在") unless subject && subject.shop_task.is_available?
      subject.read_subject_participator.increment
      stars = subject.shop_task.core_stars.select("core_stars.id, core_stars.name, core_stars.published").as_json
      subject = subject.as_json.merge(
        shop_task_id: subject.shop_task.id,
        stars: stars,
        share_url: Rails.application.routes.url_helpers.shop_subject_url(params[:task_id]),
        user_pic: subject.user.picture_url,
        pic_url: subject.picture_url,
        is_completed: (subject.shop_task.task_state["#{subject.class.to_s}:#{params[:uid]}"].to_i > 0) )
      ret = { data: subject }
      success(ret)
    end

    desc "我的订单列表"
    params do
      requires :uid, type: Integer
      requires :shop_category, type: String
      requires :status, type: Integer
      requires :select_all, type: Boolean
      requires :page, type: Integer
      requires :per_page, type: Integer
    end

    get :get_orders do
      if params[:shop_category] == 'Shop::Funding'
        @orders = Shop::FundingOrder.active.where(user_id: params[:uid]).order("created_at DESC")
        @orders = @orders.where(status: params[:status].to_i) if params[:status].present? && params[:select_all] == false
        @orders = @orders.where(status: [1, 2]) if params[:select_all] == true
        @orders = @orders.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        ret = @orders.includes([:owhat_product, :core_address]).map{
          |order| order.as_json.merge!({
            category: order.ticket_type.try(:category),
            start_at: order.owhat_product.try(:start_at),
            title: order.owhat_product.try(:title),
            address: order.owhat_product.try(:address),
            shop_address: order.owhat_product.try(:address),
            receive_name: order.try(:user_name),
            receive_mobile: order.try(:phone),
            receive_address: order.try(:address),
            pic: order.owhat_product.try(:cover_pic),
         }).update({"address" => order.owhat_product.try(:address)}) }
      else
        @orders = Shop::Order.active.includes([order_items: [:owhat_product, :core_address]]).where(user_id: params[:uid]).order("created_at DESC")
        @orders = @orders.where(status: params[:status].to_i) if params[:status].present? && params[:select_all] == false
        @orders = @orders.where(status: [1, 2]) if params[:select_all] == true
        @orders = @orders.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        if params[:from_client] == 'iOS' && Gem::Version.new(params[:app_version]) <= Gem::Version.new("3.23")
          ret = @orders.map{ |order| order.as_json.merge!({
            items: order.order_items.map{ |item| item.as_json.merge({
              category: item.ticket_type.try(:category).present? ? item.ticket_type.category+" | "+item.ticket_type.second_category : "价格出现问题，请联系客服恢复",
              start_at: item.owhat_product.try(:start_at),
              title: item.owhat_product.try(:title),
              receive_name: item.user_name,
              receive_mobile: item.phone,
              receive_address: item.address,
              pic: item.owhat_product.try(:cover_pic),
              shop_address: item.owhat_product.try(:address),
            }).update({ "address" => item.owhat_product.try(:address), "payment" => item.payment - item.freight_fee })
          } }) }
        else
          ret = @orders.map{ |order| order.as_json.merge!({
            items: order.order_items.map{ |item| item.as_json.merge({
              category: item.ticket_type.try(:category).present? ? item.ticket_type.category+" | "+item.ticket_type.second_category : "价格出现问题，请联系客服恢复",
              start_at: item.owhat_product.try(:start_at),
              title: item.owhat_product.try(:title),
              receive_name: item.user_name,
              receive_mobile: item.phone,
              receive_address: item.address,
              pic: item.owhat_product.try(:cover_pic),
              shop_address: item.owhat_product.try(:address),
            }).update({ "address" => item.owhat_product.try(:address)})
          } }) }
        end
      end
      success({data: {orders: ret, count: @orders.total_entries }})
    end

    desc "取消订单"
    params do
      requires :uid, type: Integer
      requires :order_no, type: String
      requires :shop_category, type: String
    end

    post :cancel_order do
      if params[:shop_category] == 'Shop::Funding'
        @order = Shop::FundingOrder.where(user_id: params[:uid], order_no: params[:order_no]).first
      else
        @order = Shop::Order.where(user_id: params[:uid], order_no: params[:order_no]).first
      end
      return fail(0, '找不到该订单') unless @order
      return fail(0, '已经支付或者已经取消，不能取消订单') unless @order.can_order_pay_and_cancel?
      status = ActiveRecord::Base.transaction do
        @order.cancel_alipay_weixin_order
        unless params[:shop_category] == 'Shop::Funding'
          @order.order_items.each do |o|
            o.update(status: -2)
          end
          @order.update(status: -2)
          @order.order_items.each do |item|
            item.ticket_type.participator.decr(item.quantity)
          end
        else
          @order.update(status: -2)
        end
      end
      if status
        CoreLogger.info(logger_format(api: "cancel_order", shop_category: params[:shop_category], order_id: @order.try(:id) ))
        success({data: {order_no: @order.order_no}})
      else
        fail(0, '取消订单失败')
      end
    end


    desc "分享回调送积分"
    params do
      requires :share_id, type: Integer
      optional :type, type: String
    end
    get :share_callback do
      current_user = Core::User.find_by(id: params[:uid])
      count = current_user.task_awards.where(from: "#{params[:type].blank? ? 'task_share' : params[:type]}_share").count
      case params[:type]
      when 'timeline'
        user = Core::User.active.find_by(id: params[:share_id])
        AwardWorker.perform_async(current_user.id, user.id, user.class.name, 2, 1, 'timeline_share', :award)
      when 'user'
        user = Core::User.active.find_by(id: params[:share_id])
        empirical_value, obi = 2, 1
        AwardWorker.perform_async(current_user.id, user.id, user.class.name, 2, 1, 'user_share', :award)
      when 'star'
        star = Core::Star.active.find_by(id: params[:share_id])
        AwardWorker.perform_async(current_user.id, star.id, star.class.name, 2, 1, 'star_share', :award)
      when 'app'
        user = Core::User.active.find_by(id: params[:share_id])
        AwardWorker.perform_async(current_user.id, user.id, user.class.name, 2, 1, 'app_share', :award)
      when 'topic_dynamic'
        dynamic = Shop::TopicDynamic.find_by(id: params[:share_id])
        dynamic.update(foward_count: dynamic.foward_count+1)
        AwardWorker.perform_async(current_user.id, dynamic.id, dynamic.class.name, 2, 1, 'topic_dynamic_share', :award)
      else
        task = Shop::Task.active.find_by(id: params[:share_id])
        AwardWorker.perform_async(current_user.id, task.tries(:shop, :id), task.tries(:shop, :class, :name), 2, 1, 'task_share', :award)
      end
      CoreLogger.info(logger_format(api: "share_callback", type: params[:type], share_id: params[:share_id] ))
      success({data: { count: count+1 }})
    end

    desc "创建直播评论"
    params do
      requires :content, type: String
      requires :uid, type: Integer
      requires :subject_id, type: Integer
    end
    post :create_shop_subject_comment do
      subject = Shop::Subject.where(id: params[:subject_id]).first
      return fail(0, "该直播不存在") unless subject && subject.shop_task.is_available?
      status = ActiveRecord::Base.transaction do
        @comment = Shop::Comment.new({user_id: params[:uid], content: params[:content], task_id: params[:subject_id], task_type: 'Shop::Subject', parent_id: 0})
        @comment.save
      end
      if status
        AwardWorker.perform_async(params[:uid], @comment.id, @comment.class.name, 2, 1, 'self', :award)
        CoreLogger.info(logger_format(api: "create_shop_subject_comment", comment_id: @comment.try(:id) ))
        success({data: {subject_id: params[:subject_id]}})
      else
        fail(0, '创建直播评论失败')
      end
    end

    desc "直播评论列表"
    params do
      requires :uid, type: Integer
      requires :subject_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :get_shop_subject_comment do
      subject = Shop::Subject.where(id: params[:subject_id]).first
      return fail(0, "该直播不存在") unless subject && subject.try(:shop_task).try(:is_available?)
      comments = Shop::Comment.active
        .where(task_id: params[:subject_id], task_type: 'Shop::Subject')
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
          created_at: c.created_at
        }
      end
      success({data: {comments: comments, count: count}})
    end

    desc "商品活动应援参与用户"
    params do
      requires :uid, type: Integer
      requires :shop_id, type: Integer
      requires :shop_category, type: String
    end
    get :get_shop_users do
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 10).to_i
      user_start = (page - 1) * per_page
      user_end = (page * per_page)
      case params[:shop_category]
      when 'Shop::Funding'
        task = Shop::Funding.find_by(id: params[:shop_id])
        return fail(0, "找不到该任务！！！") unless task.present?
        ret= Rails.cache.fetch("funding_participators_shop_id_#{task.id}_all", expires_in: 5.minutes) do
          orders = Shop::FundingOrder.find_by_sql("SELECT user_id, payment, paid_at from (SELECT user_id, sum(payment) as payment, max(paid_at) as paid_at FROM shop_funding_orders WHERE status = 2 AND shop_funding_id = #{task.id} group by user_id) as orders ORDER BY payment DESC, paid_at ASC")
          [orders.as_json, orders.count]
        end
      when 'Shop::Event', 'Shop::Product'
        task = eval(params[:shop_category]).find_by(id: params[:shop_id])
        return fail(0, "找不到该任务！！！") unless task.present?
        ret = Rails.cache.fetch("owhat_product_participators_shop_id_#{task.id}_#{task.class.name}_all", expires_in: 5.minutes) do
          orders = Shop::OrderItem.find_by_sql("SELECT user_id, payment, paid_at from(SELECT user_id, sum(payment) as payment, max(paid_at) as paid_at FROM shop_order_items WHERE status = 2 AND owhat_product_id = #{task.id} AND owhat_product_type = '#{task.class.name}' group by user_id) as orders ORDER BY payment DESC, paid_at ASC")
          [orders.as_json, orders.count]
        end
      end
      ret_orders = ret[0][user_start...user_end] || []
      users = ret_orders.present? ? Hash[Core::User.where(id: ret_orders.map{|o| o["user_id"]}).map{|u| [u.id, u]}] : {}
      success({data: {
        ret: ret_orders.present? ? ret_orders.map{|order|{
          user_id: order['user_id'],
          user_name: users[order['user_id']].name,
          user_pic: users[order['user_id']].picture_url+"?imageMogr2/thumbnail/!30p",
          payment: order['payment'],
          identity: users[order['user_id']].identity,
          follow_count: users[order['user_id']].follow_count,
          followers_count: users[order['user_id']].followers_count,
        }} : [],
        count: ret[1]
      }})
    end

    desc "我的订单详情"
    params do
      requires :uid, type: Integer
      requires :shop_category, type: String
      requires :order_no, type: String
    end

    get :get_order_show do
      if params[:shop_category] == 'Shop::Funding'
        @order = Shop::FundingOrder.active.where(user_id: params[:uid], order_no: params[:order_no]).first
        return fail(0, "该订单不存在") unless @order.present?
        ret = @order.as_json.merge!({
            category: @order.ticket_type.try(:category),
            start_at: @order.owhat_product.try(:start_at),
            title: @order.owhat_product.try(:title),
            address: @order.owhat_product.try(:address),
            shop_address: @order.owhat_product.try(:address),
            receive_name: @order.try(:user_name),
            receive_mobile: @order.try(:phone),
            receive_address: @order.try(:address),
            pic: @order.owhat_product.try(:cover_pic),
         }).update({ "address" => @order.owhat_product.try(:address) })
      else
        @order = Shop::Order.active.where(user_id: params[:uid], order_no: params[:order_no]).first
        return fail(0, "该订单不存在") unless @order.present?
        ret = @order.as_json.merge!({
          items: @order.order_items.map{ |item| item.as_json.merge({
            category: item.ticket_type.try(:category).present? ? item.ticket_type.category+" | "+item.ticket_type.second_category : "价格出现问题，请联系客服恢复",
            start_at: item.owhat_product.try(:start_at),
            title: item.owhat_product.try(:title),
            receive_name: item.user_name,
            receive_mobile: item.phone,
            receive_address: item.address,
            pic: item.owhat_product.try(:cover_pic),
            shop_address: item.owhat_product.try(:address),
          }).update({ "address" => item.owhat_product.try(:address) })}
        })
      end
      success({data: {order: ret}})
    end

    desc "历史订单"
    params do
      requires :uid, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :owhat2_orders do
      page = (params[:page] || 1) - 1
      per = params[:per_page] || 10
      if @current_user.old_uid.blank? && @current_account.phone.present?
        user_id = $connection.connection.select_all("SELECT t.user_id FROM owhat.`tickets` as t WHERE t.sb_phone = #{@current_account.phone}").first['user_id'] rescue nil
        @current_user.update(old_uid: user_id) if user_id.present?
      end
      count =  $connection.connection.execute("SELECT count(*) FROM owhat.`tickets` WHERE  status = 2 AND user_id = #{@current_user.old_uid}").first.first rescue 0
      orders = $connection.connection.select_all("SELECT t.id, t.order_no, t.event_id, t.payment, t.name, t.pay_type, t.quantity, t.memo, e.title, e.cover1, e.product_type, t.address_id, t.paid_at, t.created_at, t.updated_at FROM owhat.`tickets` AS t, owhat.`events` AS e WHERE t.status = 2 AND t.user_id = #{@current_user.old_uid} AND t.event_id = e.id ORDER BY created_at DESC LIMIT #{per} OFFSET #{per*page}")
      Rails.logger.info("----------"+(orders || {}).to_json+"-------------------")
      fail(0, '操作失败') unless orders
      orders = orders.map do |order|
        {
          id: order['id'],
          order_no: order['order_no'],
          name: order['name'],
          title: order['title'],
          address: order['address_id'] && $connection.connection.execute("SELECT address FROM owhat.`addresses` WHERE  id = #{order['address_id']}").tries(:first,:first),
          total_fee: order['payment'].to_s,
          status: 'paid',
          quantity: order['quantity'],
          freight_fee: "0.0",
          paid_at: order['paid_at'].to_time+8.hours,
          created_at: order['created_at'].to_time+8.hours,
          product_type: order['product_type'],
          pay_type: order['pay_type'].to_s,
          memo: order['memo'],
          payment: order['payment'].to_f.round(2).to_s,
          pic: "http://owhat.qiniudn.com/uploads/event/cover1/#{order['event_id']}/app_cover_#{order['cover1']}"
        }
      end
      success({data: {orders: orders, count: count }})
    end

    desc '获取订单分享信息'
    params do
      requires :uid, type: Integer
      requires :order_no, type: String
      requires :category, type: String
    end
    get :get_order_share_info do
      return fail(0, "该用户不存在") if @current_user.blank?
      return fail(0, "订单不存在") unless params[:order_no].present?  && params[:category].present?
      case params[:category]
      when 'Shop::Funding'
        order = Shop::FundingOrder.where(order_no: params[:order_no]).first
        if order.present?
          share_info = order.share_info
          user_share_info = order.user.weibo_auto_share_info
          CoreLogger.info(logger_format(api: "get_order_share_info", order_no: params[:order_no], category: params[:category]))
          success(data: {
            auto_share_status: user_share_info[:auto_share_status],
            has_weibo:user_share_info[:has_weibo],
            weibo_token_active:user_share_info[:weibo_token_active],
            share_info:share_info
          })
        else
          return fail(0, "订单不存在")
        end
      else
        return fail(0, "订单不存在")
      end
    end

  end
end
