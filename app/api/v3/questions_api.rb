module V3
  class QuestionsApi < Grape::API
    format :json

    before do
      check_sign
      params_hash
    end

    params do
      requires :title, type: String
      requires :pic, type: String
      requires :star_list, type: String
      requires :is_share, type: Boolean
      requires :questions_attributes, type: Hash do
        optional :title, type: String
        optional :pic, type: String
        requires :answers_attributes, type: Hash do
          optional :content, type: String
          optional :right, type: Boolean
        end
      end
    end
    post :create_question do
      question = Qa::Poster.new(params_hash)
      if question.save
        CoreLogger.info(logger_format(api: "create_question", question_id: question.try(:id)))
        success({data: true})
      else
        fail(0, '创建动态失败')
      end
    end

    params do
      requires :poster_id, :Integer
    end
    get :show_question do
      poster = Qa::Poster.find_by(id: params[:poster_id])
      return fail(0, "该问答不存在") unless poster && poster.active
      complete = poster.shop_task.task_state["#{poster.class.to_s}:#{@current_user.id}"].to_i > 0
      res = {
        id: poster.id,
        title: poster.title,
        pic: poster.pic,
        share_url: Rails.application.routes.url_helpers.qa_poster_url(params[:poster_id]),
        complete: complete,
        shop_task_id: poster.shop_task.id,
        questions: poster.questions.map{|question|
          {
            id: question.id,
            title: question.title,
            pic: question.pic,
            time: 5,
            answers: question.answers.shuffle.map{|answer|
              {
                id: answer.id,
                content: answer.content,
                right: answer.right
              }
            }
          }
        }
      }
      success({data: res})
    end

    params do
      requires :id, :Integer
      requires :question_id, :Integer
      requires :answer_id, :Integer
    end
    put :qa_answer do
      task = Shop::Task.questions.find_by(shop_id: params[:id])
      question = task.shop.questions.find(params[:question_id])
      if question.answer_id == params[:answer_id]
        question.shop_task.payment_obi(@current_user, status: :complete)
        success({data: true})
      else
        fail(0, "很遗憾答错了")
      end
    end

    params do
      requires :task_id, :Integer
      requires :count, :Integer
    end
    put :qa_complete do
      task = Shop::Task.questions.find_by(shop_id: params[:task_id])
      obi = params[:count].to_i

      unless task.task_state["#{task.shop_type}:#{@current_user.id}"].to_i > 0
        AwardWorker.perform_async(@current_user.id, task.shop_id, task.shop_type, obi, obi, 'self', :award)
        task.task_state["#{task.shop_type}:#{@current_user.id}"] = 1
      end
      CoreLogger.info(logger_format(api: "qa_complete", task_id: task.try(:id)))
      success({data: true})
    end
  end
end
