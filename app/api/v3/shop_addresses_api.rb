# encoding:utf-8
module V3
  class ShopAddressesApi < Grape::API
    format :json

    before do
      check_sign
    end

    desc "默认地址返回"
    params do
      requires :uid, type: Integer
    end

    get :get_address do
      addresses = Core::Address.active.where(user_id: params[:uid]).select("id, province_id, city_id, district_id, addressee AS receive_name, mobile, address, is_default, zip_code")
      addresses = addresses.map{|a| a.as_json.merge!({full_address: a.full_address})}
      ret = {data: addresses}
      success(ret)
    end

    desc "新增地址"
    params do
      requires :user_id, type: Integer
      requires :mobile, type: String
      requires :addressee, type: String
      requires :is_default, type: Boolean
      requires :address, type: String
      requires :city_id, type: Integer
      requires :province_id, type: Integer
      requires :district_id, type: Integer
      requires :zip_code, type: String
    end

    post :create_address do
      @address = Core::Address.new(params_hash)
      if @address.save
        CoreLogger.info(logger_format(api: "create_address", address_id: @address.try(:id)))
        # address = address.as_json.merge!({full_address: address.full_address})}
        success({data: true})
      else
        messages = @address.errors.messages
        error_memessages = messages.present? ? "您地址编辑存在异常: #{messages.map{|k, v| "#{I18n.t(k)}：#{v.join("").gsub(/(|)/,'')}"}.join(",")}" : "地址创建不能创建超过50个"
        fail(0, error_memessages)
      end
    end

    desc "地址省列表"
    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :get_provinces do
      areas = ADDRESS['0'].keys.paginate(page: params[:page] || 1, per_page: params[:per_page] || 100)
      areas = areas.map{|a| {a => ADDRESS_DATA[a]}}
      ret = {data: areas}
      success(ret)
    end

    desc "城市列表"
    params do
      requires :province_id, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :get_cities do
      areas = ADDRESS["0,#{params[:province_id].to_i}"].keys.paginate(page: params[:page] || 1, per_page: params[:per_page] || 100).as_json
      areas = areas.map{|a| {a => ADDRESS_DATA[a]}}
      ret = {data: areas}
      success(ret)
    end

    desc "区列表"
    params do
      requires :province_id, type: String
      requires :city_id, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :get_districts do
      return fail(0, "省市列表缺参数！") if params[:province_id].blank? || params[:city_id].blank?
      areas = ADDRESS["0,#{params[:province_id].to_i},#{params[:city_id].to_i}"]
      if areas.present?
        areas = areas.keys.paginate(page: params[:page] || 1, per_page: params[:per_page] || 100).as_json
        areas = areas.map{|a| {a => ADDRESS_DATA[a]}}
      else
        areas = [{4850=>"其他区"}]
      end

      ret = {data: areas}
      success(ret)
    end

    desc '删除地址'
    params do
      requires :user_id, type: Integer
      requires :address_id, type: Integer
    end
    delete :delete_address do
      add = Core::Address.find_by(id: params[:address_id], user_id: params[:user_id])
      if add
        if add.update(active: false)
          CoreLogger.info(logger_format(api: "delete_address", address_id: add.try(:id)))
          success({data: true})
        else
          fail(0, "删除地址失败")
        end
      else
        fail(0, "找不到该地址")
      end
    end

    desc '修改地址'
    params do
      requires :user_id, type: Integer
      requires :address_id, type: Integer
      requires :address, type: String
      requires :province_id, type: Integer
      requires :city_id, type: Integer
      requires :district_id, type: Integer
      requires :addressee, type: String
      requires :mobile, type: String
      requires :zip_code, type: String
    end

    post :modificate_address do
      add = Core::Address.find_by(id: params[:address_id], user_id: params[:user_id])
      if add
        add.update(address: params[:address], city_id: params[:city_id], district_id: params[:district_id], province_id: params[:province_id], mobile: params[:mobile], addressee: params[:addressee], zip_code: params[:zip_code])
        CoreLogger.info(logger_format(api: "modificate_address", address_id: add.try(:id)))
        success({data: true})
      else
        fail(0, "找不到该地址")
      end
    end

    desc '设为默认地址'
    params do
      requires :user_id, type: Integer
      requires :address_id, type: Integer
    end

    post :default_address do
      add = Core::Address.find_by(user_id: params[:user_id], id: params[:address_id])

      if add
        add.update(is_default: true)
        CoreLogger.info(logger_format(api: "default_address", address_id: add.try(:id)))
        success({data: true})
      else
        fail(0, "找不到该地址")
      end
    end

  end

end
