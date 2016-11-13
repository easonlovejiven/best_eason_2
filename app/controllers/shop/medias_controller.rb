class Shop::MediasController < Shop::ApplicationController
  def index
    Shop::Media.active
  end

  def new
    raise "没有权限" unless @current_user.verified
    @medium = Shop::Media.new
  end

  def edit
    @medium = Shop::Media.active.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @medium.present?
    return redirect_to '/', alert: "没有权限" unless @medium.user_id == @current_user.id && @current_user.verified
  end

  def update
    @medium = Shop::Media.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @medium.user_id == @current_user.id && @current_user.verified
    medium_params = params.require(:shop_media).permit(:id, :guide, :title, :url, :start_at, :end_at, :pic, :is_share, star_list: [])
    medium_params = medium_params.merge(user_id: @current_user.id)
    medium_params[:star_list].map do |star|
      next unless star.present?
      return redirect_to :back, alert: "您发布的明星不在我们的列表中哦， 请联系客服添加。"  unless Core::Star.active.published.find_by(id: star).present?
    end
    begin
      ActiveRecord::Base.transaction do
        @medium.update!(medium_params) && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Medias", action: 'update', media_id: @medium.try(:id), current_user: @current_user.try(:id))
      if @medium.shop_task.try(:published) == true
        render '/home/home/_step3', locals: {path: shop_media_path(@medium), action: 'update'}
      else
        redirect_to preview_shop_media_path(@medium)
      end
    else
      @medium.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @medium.errors.full_messages.first.blank?
      render :edit
    end
  end

  def preview
    @medium = Shop::Media.active.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @medium.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @medium.shop_task.published == true
  end

  def create
    return redirect_to '/', alert: "没有权限" unless @current_user.verified
    begin
      medium_params = params.require(:shop_media).permit(:id, :guide, :title, :url, :start_at, :end_at, :pic, :is_share, star_list: [])
      medium_params = medium_params.merge(user_id: @current_user.id)
      @medium = Shop::Media.new(medium_params)
      ActiveRecord::Base.transaction do
        @medium.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Medias", action: 'create', media_id: @medium.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_shop_media_path(@medium)
    else
      @medium.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @medium.errors.full_messages.first.blank?
      render :new
    end
  end

  def show
    return redirect_to '/' unless params[:id].present?
    @media = Shop::Media.active.find_by(id: params[:id])
    return redirect_to '/', alert: "该任务还未发布" unless @media.present? && @media.shop_task.published?
    return redirect_to new_session_path(redirect: shop_media_path(@media)) unless @current_user.present?
    @media.read_subject_participator.increment
    if @media.present? && @current_user.present?
      size = Core::TaskAward.where(task_id: @media.id, task_type: "Shop::Media", user_id: @current_user.id, from: 'self').size
      AwardWorker.perform_async(@current_user.id, @media.id, @media.class.name, 2, 1, 'self', :award) if size <= 0
    end
    return redirect_to extlink(@media.url.to_s) if @media.kind == 'url'
  end
end
