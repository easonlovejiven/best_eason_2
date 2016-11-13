class Shop::TopicsController < Shop::ApplicationController

  def index
    @topics = Shop::Topic.active
  end

  def edit
    @topic = Shop::Topic.active.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @topic.present?
    return redirect_to '/', alert: "没有权限" unless @topic.user_id == @current_user.id && @current_user.verified
  end

  def show
    return redirect_to '/', alert: "该话题不存在" unless params[:id].present?
    @topic = Shop::Topic.find_by(id: params[:id])
    @task = @topic.try(:shop_task)
    return redirect_to '/', alert: "该话题不存在" unless @topic.present? && @task.is_available?
    @dynamics = @topic.dynamics.where(active: true).includes(:pictures, :user, :videos)
    if params[:status] == 'high'
      @dynamics = @dynamics.order("like_count DESC")
    else
      @dynamics = @dynamics.order("created_at ASC")
    end
    @dynamics = @dynamics.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
    @dynamic = Shop::TopicDynamic.new
    topic_dynamic_vote_results = @current_user.present? ? Hash[Shop::VoteResult.where(resource_id: @dynamics.map(&:id),resource_type: "Shop::TopicDynamic", user_id: @current_user.id).group_by(&:resource_id).map{|c, r| [c, r.first.shop_vote_option_id]}] : {}
    @votes = Hash[Shop::VoteOption.where(voteable_id: @dynamics.map(&:id),voteable_type: "Shop::TopicDynamic").group_by(&:voteable_id).map{|id, value|[id,{
      is_voted: topic_dynamic_vote_results[id].present?,
      participator: value.map{|c| c.vote_count.to_i}.sum || 0,
      detail: value.map{|d|{
        id: d.try(:id),
        content: d.try(:content),
        voted_count: (d.try(:vote_count) || 0).to_i,
        is_choosed: (topic_dynamic_vote_results[id] || 0) == d.try(:id)
      }}
    }]}]
  end

  #发话题
  def new
    raise "没有权限" unless @current_user.verified
    @topic = Shop::Topic.new
  end

  def create
    return redirect_to '/', alert: "没有权限" unless @current_user.verified
    begin
      @topic = Shop::Topic.new(shop_topics_params)
      ActiveRecord::Base.transaction do
        @topic.save! && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Topics", action: 'create', topic_id: @topic.try(:id), current_user: @current_user.try(:id))
      AwardWorker.perform_async(@current_user.id, @topic.id, @topic.class.name, 4, 2, 'self', :award )
      redirect_to preview_shop_topic_path(@topic)
    else
      @topic.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @topic.errors.full_messages.first.blank?
      render :new
    end
  end

  def update
    @topic = Shop::Topic.find_by(id: params[:id])
    return redirect_to '/', alert: "没有权限" unless @topic.user_id == @current_user.id && @current_user.verified
    shop_topics_params[:star_list].map do |star|
      next unless star.present?
      return redirect_to :back, alert: "您发布的明星不在我们的列表中哦， 请联系客服添加。"  unless Core::Star.active.published.find_by(id: star).present?
    end
    begin
      ActiveRecord::Base.transaction do
        @topic.update!(shop_topics_params) && @save_ret = true
      end
    rescue Exception => e
      Rails.logger.fatal e
      Rails.logger.fatal caller
    end
    if @save_ret == true
      CoreLogger.info(controller: "Shop::Topics", action: 'update', topic_id: @topic.try(:id), current_user: @current_user.try(:id))
      if @topic.shop_task.try(:published) == true
        render '/home/home/_step3', locals: {path: shop_topic_path(@topic), action: 'update'}
      else
        redirect_to preview_shop_topic_path(@topic)
      end
    else
      @topic.errors.add(:title, "创建任务失败，请检查下活动内容哟～不要添加表情符号哦，O妹会崩溃的！") if @topic.errors.full_messages.first.blank?
      render :edit
    end
  end

  #创建动态回复
  def create_dynamic
    return redirect_to '/', alert: "没有权限" if shop_dynamic_comments_params[:user_id].to_i != @current_user.id
    @current_user.create_dynamic_lock.lock do
      return redirect_to '/', alert: "该话题不存在" unless shop_dynamic_comments_params[:shop_topic_id].present?
      @topic = Shop::Topic.find_by(id: shop_dynamic_comments_params[:shop_topic_id])
      return redirect_to '/', alert: "该话题不存在" unless @topic.present? && @topic.shop_task.is_available?
      return redirect_to :back, alert: "动态不在列表中哦！" unless @topic.present?
      return redirect_to :back, alert: "您发布的动态不能超过3条！" if @topic.topic_dynamic_state["#{shop_dynamic_comments_params[:user_id]}"].to_i >= 3
      params_hash = {}
      shop_dynamic_comments_params.each do |k, v|
        if ["user_id", "shop_topic_id"].include? k
          params_hash.merge!({ k => v.to_i })
        else
          params_hash.merge!({ k => v })
        end
      end
      ActiveRecord::Base.transaction do
        @d = Shop::TopicDynamic.create!(params_hash)
      end
      AwardWorker.perform_async(@current_user.id, @d.id, @d.class.name, 4, 2, 'create_topic_dynamic', :award )
      CoreLogger.info(controller: "Shop::Topics", action: 'create_dynamic', topic_dynamic_id: @d.try(:id), current_user: @current_user.try(:id))
      redirect_to shop_topic_path(id: params_hash['shop_topic_id'])
    end
  rescue Exception => e
    #return render text: { error: '我们暂不支持带符号表情的第三方用户注册登录，请去掉您的表情符号吧。'}
    flash[:notice] = '我们暂不支持带符号表情动态发送，请去掉您的表情符号吧。'
    redirect_to shop_topic_path(@topic)
  end

  #赞动态
  def dynamic_like
    @current_user.like_dynamic_lock.lock do
      @dynamic = Shop::TopicDynamic.find_by(id: params[:dynamic_id])
      @topic = @dynamic.topic
      @list = Redis::List.new "shop_topic_dynamic_#{params[:dynamic_id]}_likes"
      unless @list.values.include?(current_user.id.to_s)
        @dynamic.update(like_count: @dynamic.like_count+1) #更新动态的赞数
        @topic.topic_like_count.increment #更新话题的赞数
        @list << @current_user.id #为动态储存攒的人
        AwardWorker.perform_async(@current_user.id, @dynamic.id, @dynamic.class.name, 1, 0, 'self', :award )
        AwardWorker.perform_async(@dynamic.user_id, @dynamic.id, @dynamic.class.name, 2, 0, 'other', :award )
        @like_count = @dynamic.like_count
        CoreLogger.info(controller: "Shop::Topics", action: 'dynamic_like', dynamic_id: @dynamic.try(:id), current_user: @current_user.try(:id))
        respond_to do |format|
          format.js {}
        end
      else
        @like_count = @dynamic.like_count
      end
    end
  end

  def preview
    @topic = Shop::Topic.find_by(id: params[:id])
    redirect_to '/', alert: "不是你本人发布的任务，不能预览" and return unless @topic.user_id == @current_user.id
    redirect_to '/', alert: "任务已经发布，不能预览" and return if @topic.shop_task.published == true
    @dynamics = []
    @dynamic = Shop::TopicDynamic.new
  end

  def create_dynamic_vote
    respond_to do |format|
      format.json do
        return render json: { error: '您未登录！！！', unlogin: true} if @current_user.blank?
        @current_user.create_dynamic_lock.lock do
          topic = Shop::Topic.find_by(id: params[:id])
          return render json: { error: '该话题不存在'} unless topic && topic.try(:shop_task).try(:is_available?)
          return render json: { error: '您发布的动态不能超过3条！'} if topic.topic_dynamic_state["#{@current_user.try(:id)}"].to_i >= 3
          votes = params[:vote_option].values
          return render json: { error: '参数错误'} unless votes.is_a?(Array)
          dynamic = Shop::TopicDynamic.new({
            shop_topic_id: topic.id,
            content: params[:title],
            user_id: @current_user.try(:id),
            vote_options_attributes: votes.map{|v| v.merge({user_id: @current_user.try(:id)})}
          })
          if dynamic.save
            AwardWorker.perform_async(@current_user.id, dynamic.id, dynamic.class.name, 4, 2, 'create_topic_dynamic', :award )
            CoreLogger.info(controller: "Shop::Topics", action: 'create_dynamic_vote', dynamic_id: dynamic.try(:id), current_user: @current_user.try(:id))
            render json: {}
          else
            render json: { error: '创建动态失败'}
          end
        end
      end
    end
  end

  private

  def shop_topics_params
    params.require(:shop_topic).permit(:guide, :title, :description, :cover1, :is_share, :key, :user_id, :creator_id, :shop_category, star_list: [])
  end

  def shop_dynamic_comments_params
    params.require(:shop_topic_dynamic).permit(:content, :user_id, :shop_topic_id, pictures_attributes: [:pictureable_id, :pictureable_type, :key], videos_attributes: %w{id videoable_id videoable_type key user_id })
  end

  def authorized?
    super
    return true if %w[show create_dynamic_vote].include?(params[:action])
    !!@current_user
  end

end
