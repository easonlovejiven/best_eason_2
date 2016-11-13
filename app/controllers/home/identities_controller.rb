class Home::IdentitiesController < Home::ApplicationController

  def create
    return redirect_to edit_home_users_path, alert: "您已经是认证用户" if @current_user.verified?
    return redirect_to edit_home_users_path, alert: "您的申请在审核中" if @current_user.identities.active.where(status: 0).present?
    @identity = Core::Identity.new(params.require(:core_identity).permit(:is_org,:name,:phone,:position,:org_name,:org_pic,:id_pic,:id_pic2,:user_id,:creator_id,:description).merge(related_ids: params[:core_identity][:related_ids]))
    if @identity.save
      CoreLogger.info(controller: 'Home::Identities', action: 'create', identity: @identity.as_json, current_user: @current_user.try(:id))
      redirect_to action: :success
    else
      redirect_to action: :failure
    end
  end
end
