# encoding:utf-8
module V3
  class AjaxApi < Grape::API
    format :json

    desc "用户个人价格分类查询"
    params do
      requires :uid, type: Integer
    end
    get :get_user_price_category do
      @categories = Shop::PriceCategory.where(user_id: params[:uid]).select("id, name").as_json
      return @categories
    end

    desc "运费模板"
    params do
      requires :uid, type: Integer
    end
    get :get_user_freight_templates do
      @templates = Shop::FreightTemplate.where(user_id: params[:uid]).select("id, name").as_json
      return @templates
    end

    desc "app请求二维码"
    params do
      requires :uid, type: Integer
      requires :category, type: String
    end

    get :app_publish_task do
      ##过期时间， 用户id, category
      code = Redis.current.get("#{params[:rand]}")
      if code.present?
        j_code = JSON.parse(code)
        if j_code[1]
          return fail(0, '您已经登录过')
        elsif params[:uid].blank?
          return fail(0, '缺少uid参数和category参数')
        else
          j_code = j_code.each_with_index.map{ |v, i| i == 1 ? params[:uid] :  i == 2 ? params[:category] : v }
          Redis.current.set "#{params[:rand]}", j_code
          return success({data: true})
        end
      else
        return fail(0, '网络情况异常')
      end
    end

    desc "web持续请求二维码是否跳转接口"
    params do
      requires :rand, type: Integer
    end

    get :turn_to_publish do
      code = Redis.current.get("#{params[:rand]}")
      if code.present?
        j_code = JSON.parse(code)
        return fail(0, '已过期') if j_code[0].to_time < Time.now
        if j_code[1]
          return success({data: {uid: j_code[1], category: j_code[2]} })
        else
          return fail(0, '用户还没有扫描信息')
        end
      else
        return fail(0, '网络链接异常')
      end
    end

    desc "客户端接口请求"
    get :get_web_address do
      success({data: {
          address: "#{Rails.application.routes.default_url_options[:host]}"
      }})
    end

    desc "更新"
    params do
      # requires :version, type: String
    end
    get :version_update do
      low_version = Gem::Version.new("3.0.1")
      app_version = Gem::Version.new(params[:app_version])
      high_version = Gem::Version.new("3.1.5")
      if app_version == "5.0.0"
        #有重大bug 必须强制更新
        success({data: {home_show: true, is_force: true, is_update: true, new_version: "3.1.5", url: "http://qimage.owhat.cn/7f9505ea2909493b1a5f79cf232a6ff0.apk"}})
      elsif app_version >= low_version && app_version < high_version
        success({data: {home_show: true, is_force: false, is_update: true, new_version: "3.1.5", url: "http://qimage.owhat.cn/7f9505ea2909493b1a5f79cf232a6ff0.apk"}})
      elsif app_version >= high_version
        success({data: {home_show: false, is_force: false, is_update: false, new_version: "3.1.5", url: "http://qimage.owhat.cn/7f9505ea2909493b1a5f79cf232a6ff0.apk"}})
      else
        success({data: {home_show: true, is_force: true, is_update: true, new_version: "3.1.5", url: "http://qimage.owhat.cn/7f9505ea2909493b1a5f79cf232a6ff0.apk"}})
      end

    end

  end
end
