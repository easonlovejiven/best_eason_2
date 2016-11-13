class Shop::VoteOptionsController < Shop::ApplicationController
  def vote_dynamic
    respond_to do |format|
      format.json do
        return render json: { error: '您未登录！！！', unlogin: true} if @current_user.blank?
        vote_option = Shop::VoteOption.find_by(id: params[:id])
        return render json: { error: '该投票选项不存在'} unless vote_option.present?
        resource = vote_option.try(:voteable)
        return render json: { error: '该动态不存在'} unless resource.present?
        topic = resource.try(:topic)
        return render json: { error: '该话题不存在'} unless topic.present? && topic.try(:shop_task).try(:is_available?)
        vote_result = Shop::VoteResult.new({
          shop_vote_option_id: vote_option.id,
          user_id: @current_user.try(:id),
          resource_id: resource.try(:id),
          resource_type: resource.class.name
        })
        if vote_result.save
          AwardWorker.perform_async(@current_user.id, vote_result.id, vote_result.class.name, 2, 1, 'self', :award )
          CoreLogger.info(controller: "Shop::VoteOptions", action: 'vote_dynamic', vote_option_id: vote_option.try(:id), current_user: @current_user.try(:id))
          render json: {}
        else
          is_voted = (vote_result.errors[:user_id] || []).include? "你已经参与过投票了！"
          render json: { error: is_voted ? "你已经参与过投票了！" : '创建动态失败', refresh: is_voted}
        end
      end
    end
  end

  private
  def authorized?
    super
    return true if %w[vote_dynamic].include?(params[:action])
    !!@current_user
  end
end
