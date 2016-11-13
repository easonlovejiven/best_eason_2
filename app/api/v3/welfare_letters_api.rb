module V3
  class WelfareLettersApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :letter_papers do
      papers = Welfare::Paper.active.published.select('id, pic').paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      papers = papers.map do |p|
        {
          id: p.id,
          pic: p.picture_url
        }
      end
      success({data: { papers: papers.as_json } })
    end

    params do
      requires :title, type: String
      requires :paper_id, type: Integer
      requires :receiver, type: String
      requires :content, type: String
      requires :signature, type: String
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
      if @current_user.id != letter.user_id
        @complete = letter.shop_task.task_state["#{letter.class.to_s}:#{@current_user.id}"].to_i > 0
        return fail(0, 'O!元不够') unless @complete || @current_user.obi >= 5
        letter.shop_task.payment_obi(@current_user, status: :complete) and letter.shop_task.increment!(:participants) unless @complete
      end

      res = {
        id: letter.id,
        title: letter.title,
        pic: letter.tries(:paper, :picture_url) || Welfare::Paper.published.first.try(:picture_url),
        receiver: letter.receiver || "亲爱的用户",
        content: letter.content || letter.title,
        signature: letter.signature || letter.tries(:user, :name),
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
