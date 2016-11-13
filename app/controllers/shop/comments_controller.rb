class Shop::CommentsController < Shop::ApplicationController
  skip_before_filter :login_filter, only: [:index]

  def create
    @comment = Shop::Comment.new(shop_comment_params)
    if @comment.save
      AwardWorker.perform_async(@current_user.id, @comment.id, @comment.class.name, 2, 1, 'self', :award )
      CoreLogger.info(controller: "Shop::Comments", action: 'create', comment_id: @comment.try(:id), current_user: @current_user.try(:id))
      respond_to do |format|
        format.html { redirect_to shop_subject_path(id: @comment.task.id) }
      end
    end
  end

  private

  def shop_comment_params
    params.require(:shop_comment)
      .permit(:id, :parent_id, :task_id, :task_type, :content, :user_id)
  end

end
