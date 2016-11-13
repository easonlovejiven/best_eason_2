class Welfare::LettersController < Home::ApplicationController
  def index
    welfares = Shop::Task.welfares.published
    welfares = welfares.where(shop_type: Shop::Task::CATEGORY[params[:type]]) if %w(event product letter voice).include?(params[:type].to_s)
    welfares_scope = case params[:order]
    when "hot"
      welfares.populars
    when "time"
      welfares.newests
    else
      welfares.tops
    end
    @welfares = welfares_scope.populars.select("id, title, description, shop_type, shop_id, guide, pic, user_id, created_at, participants, category").paginate(page: params[:page] || 1, per_page: params[:per_page] || 12)
  end

  def show
    return redirect_to '/', alert: "该任务还未发布" unless params[:id].present?
    @letter = Welfare::Letter.find_by(id: params[:id])
    return redirect_to '/', alert: "该任务还未发布" unless @letter && @letter.shop_task.published?
    @user = Core::User.where(id: (@letter.user_id || @letter.creator_id)).first
  end

  def buy
    return redirect_to '/' unless params[:id].present?
    letter = Welfare::Letter.find_by(id: params[:id])
    if @current_user.id != letter.user_id
      complete = letter.shop_task.task_state["#{letter.class.to_s}:#{@current_user.id}"].to_i > 0
      raise "O!元不足" unless complete || @current_user.obi >= 5
      letter.shop_task.payment_obi(@current_user, status: :complete) unless complete
      CoreLogger.info(controller: "Welfare::Letters", action: 'buy', letter_id: letter.try(:id), current_user: @current_user.try(:id)) unless complete
    end
    render json: { success: true }
  end

  def new
    raise "普通用户不能发布福利" unless @current_user.verified
    @letter = Welfare::Letter.new
  end

  def create
    return redirect_to '/', alert: "普通用户不能发布福利" unless @current_user.verified
    begin
      @letter = Welfare::Letter.new
      @letter.attributes = params.require(:welfare_letter).permit(*@letter.manage_fields).merge(user_id: @current_user.id)
      ActiveRecord::Base.transaction do
        @letter.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Welfare::Letters", action: 'create', letter_id: @letter.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_welfare_letter_path(@letter)
    else
      @letter.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @letter.errors.full_messages.first.blank?
      render :new
    end
  end

  def show_voice
    @voice = Welfare::Voice.find params[:id]
    if @current_user.id != @voice.user_id
      complete = @voice.shop_task.task_state["#{@voice.class.to_s}:#{@current_user.id}"].to_i > 0
      return redirect_to '/', alert: "O!元不足"  unless complete || @current_user.obi >= 5
      @voice.shop_task.payment_obi(@current_user, status: :complete) unless complete
      CoreLogger.info(controller: "Welfare::Letters", action: 'show_voice', voice_id: @voice.try(:id), current_user: @current_user.try(:id)) unless complete
    end
    render json: { success: true }
  end

  def preview
    @letter = Welfare::Letter.active.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @letter.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @letter.shop_task.published == true
    @user = Core::User.active.find_by id: (@letter.user_id || @letter.creator_id)
  end

  def authorized?
    super
    return true if %w[index].include?(params[:action])
    !!@current_user
  end
end
