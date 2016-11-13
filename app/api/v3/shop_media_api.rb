module V3
  class ShopMediaApi < Grape::API
    format :json

    before do
      check_sign
      params_hash
    end

    params do
      requires :title, type: String
      requires :start_at, type: DateTime
      requires :end_at, type: DateTime
      requires :star_list, type: String, desc: "关联明星"
      requires :url, type: String
      requires :pic, type: String
      optional :is_share, type: String
    end
    post :publish_mediua do
      params_hash.delete('is_share') #o妹精选去掉is_share
      medium = Shop::Media.new(params_hash)
      if medium.save
        CoreLogger.info(logger_format(api: "publish_mediua", medium_id: medium.try(:id)))
        success({data: true})
      else
        fail(0, '创建失败')
      end
    end

    params do
      requires :uid, :Integer
      requires :medium_id, :Integer
    end
    get :show_medium do
      medium = Shop::Media.find_by(id: params[:medium_id])
      return fail(0, "该O妹精选不存在") unless medium && medium.shop_task.is_available?
      medium.read_subject_participator.increment
      size = Core::TaskAward.where(user_id:  @current_user.id, task_type: "Shop::Media", task_id: medium.id).where("`from` = 'self' AND created_at > ? ", Time.now.beginning_of_day.to_s(:db)).size
      AwardWorker.perform_async(@current_user.id, medium.id, medium.class.name, 2, 1, 'self', :award) if size <= 10
      stars = medium.shop_task.core_stars.select("core_stars.id, core_stars.name, core_stars.published").as_json
      res = {
        id: medium.id,
        title: medium.title,
        pic: medium.picture_url,
        start_at: medium.start_at.to_s(:db),
        end_at: medium.end_at.to_s(:db),
        url: medium.url,
        is_completed: true,
        share_url: Rails.application.routes.url_helpers.shop_media_url(params[:medium_id]),
        shop_task_id: medium.shop_task.id,
        created_at: medium.created_at.to_s(:db),
        updated_at: medium.updated_at.to_s(:db),
        stars: stars,
        user_id: medium.user_id,
        user_pic: medium.user.picture_url,
        pic_url: medium.picture_url,
        description: medium.description || '',
        kind: medium.kind || ''
      }

      success({data: { medium: res } })
    end

  end
end
