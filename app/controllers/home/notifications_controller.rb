class Home::NotificationsController < Home::ApplicationController
  def index
    @sends = Notification::Send.active.paginate(page: params[:page] || 1, per_page: params[:per] || 10)
    @user = Core::User.find_by(id: 88)
  end
end
