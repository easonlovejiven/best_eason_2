class Shop::DynamicCommentsController < Shop::ApplicationController

  def index
    page = params[:page] || 1
    return redirect_to '/', alert: "该评论不存在" unless params[:dynamic_id].present?
    @dynamic = Shop::TopicDynamic.find_by(id: params[:dynamic_id])
    topic_dynamic_vote_results = @current_user.present? ? Hash[Shop::VoteResult.where(resource_id: @dynamic.id,resource_type: "Shop::TopicDynamic", user_id: @current_user.id).group_by(&:resource_id).map{|c, r| [c, r.first.shop_vote_option_id]}] : {}
    @votes = Hash[Shop::VoteOption.where(voteable_id: @dynamic.id,voteable_type: "Shop::TopicDynamic").group_by(&:voteable_id).map{|id, value|[id,{
      is_voted: topic_dynamic_vote_results[id].present?,
      participator: value.map{|c| c.vote_count.to_i}.sum || 0,
      detail: value.map{|d|{
        id: d.try(:id),
        content: d.try(:content),
        voted_count: (d.try(:vote_count) || 0).to_i,
        is_choosed: (topic_dynamic_vote_results[id] || 0) == d.try(:id)
      }}
    }]}]

    @topic = @dynamic.topic
    return redirect_to '/', alert: "该话题不存在" unless @topic.present? && @topic.shop_task.is_available?
    @comments = Rails.cache.fetch("shop_dynamic_comment_#{params[:dynamic_id]}") do
      Shop::DynamicComment.includes(:user).where(dynamic_id: params[:dynamic_id], parent_id: 0)
    end.paginate(page: page, per_page: 10)
    @comment = Shop::DynamicComment.new
  end

  def show
    @topic_dynamic = Shop::Dynamic.find_by(id: params[:id])
    return redirect_to '/' unless @topic_dynamic.present?
    @dynamics = @topic_dynamic.dynamics
  end

  def create
    respond_to do |format|
      params_hash = private_params shop_dynamic_comments_params, ["user_id", "dynamic_id", "parent_id"]
      @dynamic = Shop::TopicDynamic.find_by(id: params_hash['dynamic_id'])
      topic = @dynamic.try(:topic)
      unless topic.present? && topic.try(:shop_task).try(:is_available?)
        @status = false
        format.html { redirect_to '/', alert: "该话题不存在"  }
        format.js
      else
        if params_hash['parent_id'] != 0
          @parent_comment = Shop::DynamicComment.find_by(id: params_hash['parent_id'])
          @parent_username = @parent_comment.user.name
        end
        @comment = Shop::DynamicComment.new(params_hash)

        status = ActiveRecord::Base.transaction do
          @dynamic.update!(comment_count: @dynamic.comment_count+1)
          @parent_comment.update!(seed_count: @parent_comment.seed_count+1) if params_hash['parent_id'] != 0
          @comment.save
        end
        if status
          Rails.cache.delete("shop_dynamic_comment_#{params_hash['dynamic_id']}")
          #经验值 o元 发布
          AwardWorker.perform_async(@current_user.id, @comment.id, @comment.class.name, 2, 1, 'self', :award )
          CoreLogger.info(controller: "Shop::DynamicComments", action: 'create', comment_id: @comment.try(:id), current_user: @current_user.try(:id))
          format.html { redirect_to shop_dynamic_comments_path(dynamic_id: params_hash['dynamic_id']) }
          format.js
        end
      end
    end
  end

  private

  def shop_dynamic_comments_params
    params.require(:shop_dynamic_comment).permit(:content, :user_id, :parent_id, :dynamic_id)
  end

  def authorized?
    super
    return true if %w[index].include?(params[:action])
    !!@current_user
  end

  def verify_user
    raise '没有权限' unless @current_user.verified?
  end
end
