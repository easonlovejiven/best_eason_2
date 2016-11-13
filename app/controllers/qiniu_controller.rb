class QiniuController < ApplicationController

  # POST /api/qiniu_uptoken.json
  def uptoken
    put_policy = Qiniu::Auth::PutPolicy.new(
        "#{Rails.application.secrets.qiniu_host_name}",     # 存储空间
        params[:key],        # 最终资源名，可省略，即缺省为“创建”语义
        # expires_in, # 相对有效期，可省略，缺省为3600秒后 uptoken 过期
        # deadline    # 绝对有效期，可省略，指明 uptoken 过期期限（绝对值），通常用于调试
    )

    render json: {
      uptoken: Qiniu::Auth.generate_uptoken(put_policy),
      qiniu_host: Settings.qiniu["host"]
    }
  end

  private

  def authorized?
    if params[:action] == 'uptoken'
      #不需要登陆的方法放在此处,需要登陆无需写入
      true
    end
  end
end
