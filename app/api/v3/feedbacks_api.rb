module V3
  class FeedbacksApi < Grape::API

    format :json

    before do
      check_sign
    end

    post :feedback do
      fail(0, "参数为空") if params[:content].present?
      feedback = Core::Feedback.create(user_id: @current_user.id, content: params[:content].to_s.strip)
      CoreLogger.info(logger_format(api: "feedback", feedback_id: feedback.try(:id)))
      success(data: true)
    end

  end
end
