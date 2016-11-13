class Shop::SubjectsController < Shop::ApplicationController
  skip_before_filter :login_filter, only: [:index]

  def index
    Shop::Subject.active
  end

  def edit
    @subject = Shop::Subject.active.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @subject.present?
    return redirect_to '/', alert: "没有权限" unless @subject.user_id == @current_user.id && @current_user.verified
  end

  def show
    return redirect_to '/', alert: "该直播不存在" unless params[:id].present?
    @subject = Shop::Subject.find_by(id: params[:id])
    return redirect_to '/', alert: "该直播不存在" unless @subject.present? && @subject.shop_task.is_available?
    @comments = @subject.comments.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
    @subject.read_subject_participator.increment
    @comment = Shop::Comment.new
  end

  def new
    raise "没有权限" unless @current_user.verified
    @subject = Shop::Subject.new
    @categories = Shop::PriceCategory.all
  end

  def create
    return redirect_to '/', alert: "没有权限" unless @current_user.verified
    begin
      @subject = Shop::Subject.new(shop_subject_params)
      ActiveRecord::Base.transaction do
        @subject.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Subjects", action: 'create', subject_id: @subject.try(:id), current_user: @current_user.try(:id))
      redirect_to preview_shop_subject_path(@subject)
    else
      @subject.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @subject.errors.full_messages.first.blank?
      render :new
    end
  end

  def update
    @subject = Shop::Subject.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @subject.user_id == @current_user.id && @current_user.verified
    shop_subject_params[:star_list].map do |star|
      next unless star.present?
      return redirect_to :back, alert: "您发布的明星不在我们的列表中哦， 请联系客服添加。"  unless Core::Star.active.published.find_by(id: star).present?
    end
    begin
      ActiveRecord::Base.transaction do
        @subject.update!(shop_subject_params) && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Subjects", action: 'update', subject_id: @subject.try(:id), current_user: @current_user.try(:id))
      if @subject.shop_task.try(:published) == true
        render '/home/home/_step3', locals: {path: shop_subject_path(@subject), action: 'update'}
      else
        redirect_to preview_shop_subject_path(@subject)
      end
    else
      @subject.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @subject.errors.full_messages.first.blank?
      render :edit
    end
  end


  def like
    @subject = Shop::Subject.find_by(id: params[:id])
    @list = Redis::List.new "shop_subject_#{params[:id]}_likes"
    unless @list.values.include?(@current_user.id.to_s)
      @list << @current_user.id
      @subject.like_subject_participator.increment
      @like_count = @subject.like_subject_participator.value
      CoreLogger.info(controller: "Shop::Subjects", action: 'like', subject_id: @subject.try(:id), current_user: @current_user.try(:id))
      respond_to do |format|
        format.html
        format.json { render json:
          {
            status: true,
            data: {
              like_count: @like_count
            }
          }
        }
      end
    else
      respond_to do |format|
        format.html
        format.json { render json:
          {
            status: false,
            data: {
              like_count: @like_count
            }
          }
        }
      end
    end
  end

  def preview
    @subject = Shop::Subject.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @subject.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @subject.shop_task.published == true
    @comments = []
    @comment = Shop::Comment.new
  end

  private

  def shop_subject_params
    params.require(:shop_subject)
      .permit(:id, :guide, :title, :category, :shop_category, :description, :user_id, :creator_id, :key, :cover1, :start_at, :live_url,
       star_list: [])
  end

end
