class Qa::PostersController < Shop::ApplicationController

  def new
    raise "没有权限" unless @current_user.verified
    @poster = Qa::Poster.new
  end

  def create
    return redirect_to '/', alert: "没有权限" unless @current_user.verified
    begin
      poster_params = params.require(:qa_poster).permit(:id, :guide, :title, :is_share, star_list: [], questions_attributes: [:title, :pic, answers_attributes: [:content, :right] ])
      @poster = Qa::Poster.new(poster_params.merge(user_id: @current_user.id))
      ActiveRecord::Base.transaction do
        @poster.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Qa::Posters", action: 'create', id: @poster.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_qa_poster_path(@poster)
    else
      @poster.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @poster.errors.full_messages.first.blank?
      render :new
    end
  end

  def show
    @poster = Qa::Poster.find(params[:id])
    @parti_users = Core::TaskAward.find_by_sql("SELECT * FROM core_task_awards WHERE active = 1 AND task_id = #{@poster.id} AND task_type = '#{@poster.class.name}' LIMIT 23 OFFSET 0").map(&:user)
  end

  def answer
    poster = Qa::Poster.find(params[:id])
    question = poster.questions.find(params[:question_id])
    if question.answer_id == params[:answer_id].to_i
      # question.poster.shop_task.payment_obi(@current_user, status: :complete)
      render json: {}
    else
      render json: { message: "很遗憾答错了", right: question.answer_id }
    end
  end

  def complete
    question = Qa::Poster.find(params[:id])
    obi = params[:obi].to_i > 5 ? 5 : params[:obi].to_i
    unless question.shop_task.task_state["#{question.class.to_s}:#{@current_user.id}"].to_i > 0
      AwardWorker.perform_async(@current_user.id, question.id, question.class.to_s, obi, obi, 'self', :award)
      question.shop_task.task_state["#{question.class.to_s}:#{@current_user.id}"] = 1
    end
    CoreLogger.info(controller: "Qa::Posters", action: 'complete', id: question.try(:id), current_user: @current_user.try(:id))
    render json: { state: question.shop_task.task_state["#{question.class.to_s}:#{@current_user.id}"].to_i > 0 }
  end

  def more_users
    @task = Qa::Poster.find(params[:id])
    @users = Rails.cache.fetch("get_qa_poster_more_users_by#{@task.id}", :expires_in => 5.minute) do
      @task.awards.where(active: 1).order(created_at: :desc).map(&:user)
    end
    @users = @users.paginate(page: params[:page] || 1, per_page: params[:per] || 10)
  end

  def preview
    @poster = Qa::Poster.active.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @poster.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @poster.shop_task.published == true
    @parti_users = []
  end
end
