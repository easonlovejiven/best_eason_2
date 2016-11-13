class Manage::Core::IdentitiesController < Manage::PatternsController
  def accept
    @identity = Core::Identity.active.find_by id: params[:id]
    return '已是认证用户' if @identity.user.verified?
    database_transaction do
      @identity.user.update!(identity: @identity.is_org ? 2 : 1, verified: true, verified_at: Time.now)
      @identity.update!(status: 1)
    end
    CoreLogger.info(controller: 'Manage::Core::Identities', action: 'accept', identity_id: params[:id], current_user: @current_user.try(:id))
    redirect_to manage_core_identities_path
  end

  def reject
    @identity = Core::Identity.active.find_by id: params[:id]
    @identity.update(status: -1)
    CoreLogger.info(controller: 'Manage::Core::Identities', action: 'reject', identity_id: params[:id], current_user: @current_user.try(:id))
    redirect_to manage_core_identities_path
  end
end
