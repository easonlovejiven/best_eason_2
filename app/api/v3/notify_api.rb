# encoding:utf-8
module V3
  class NotifyApi < Grape::API
    format :json

    desc "七牛回调接口"
    get :qiniu_notify do
      Rails.logger.info "七牛回调接口传回参数：------>#{params}"
    end

    desc "七牛上传获取token接口"
    params do
      requires :uid, type: Integer
      requires :key, type: String
      optional :formats, type: String
    end
    post :qiniu_uptoken do
      #要验证用户
      # user = Core::User.find(params[:uid])
      # return fail(0, '该用户不存在') unless user
      put_policy = Qiniu::Auth::PutPolicy.new(
        "#{Rails.application.secrets.qiniu_host_name}",     # 存储空间
        params[:key], # 最终资源名，可省略，即缺省为“创建”语义
      )
      ret = {
        uptoken: Qiniu::Auth.generate_uptoken(put_policy),
        qiniu_host: Settings.qiniu["host"],
        key: params[:key]
      }
      success({data: ret})
    end

  end
end
