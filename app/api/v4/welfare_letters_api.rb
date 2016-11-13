module V4
  class WelfareLettersApi < Grape::API
    format :json

    before do
      check_sign
    end

    params do
      requires :title, type: String
      requires :star_list, type: String
      requires :pic, type: String
      requires :images_attributes, type: Hash do
        optional :pic, type: String
      end
    end
    post :publish_letter do
      letter = Welfare::Letter.new(params_hash)
      if letter.save
        CoreLogger.info(logger_format(api: "publish_letter", letter_id: letter.try(:id)))
        success({data: true})
      else
        fail(0, '创建动态失败')
      end
    end

    params do
      requires :letter_id, type: Integer
    end
    get :show_letter do
      letter = Welfare::Letter.find(params[:letter_id])
      return fail(0, "该福利不存在") unless letter && letter.active
      if @current_user.id != letter.user_id
        @complete = letter.shop_task.task_state["#{letter.class.to_s}:#{@current_user.id}"].to_i > 0
        return fail(0, 'O!元不够') unless @complete || @current_user.obi >= 5
        letter.shop_task.payment_obi(@current_user, status: :complete) unless @complete
      end
      stars = letter.shop_task.core_stars.select("core_stars.id, core_stars.name, core_stars.published").as_json
      res = {
        id: letter.id,
        title: letter.title,
        stars: stars,
        user_id: letter.creator_id,
        complete: @complete,
        created_at: letter.created_at.to_s(:db),
        share_url: Rails.application.routes.url_helpers.welfare_letter_url(params[:letter_id]),
        images: letter.images.active.map do |image|
          {
            id: image.id,
            pic: image.picture_url
          }
        end
      }
      success({data: res})
    end
  end
end
