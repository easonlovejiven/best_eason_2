class Home::PunchesController < Home::ApplicationController
  def create
    star = Core::Star.published.find_by(id: params[:star_id])
    unless star.present?
      render json: { error: '没有改明星' }
      return
    end
    if @current_user.punches.where(star_id: star.id).is_punch(Time.zone.now.beginning_of_day).present?
      render json: { error: '当天已经打卡' }
      return
    end
    if @current_user.punches.is_punch(Time.zone.now.beginning_of_day).size > 4
      render json: { error: '每天只能打卡5次' }
      return
    end
    @current_user.punches.new(star_id: star.id).save
    star.increment!(:participants)
    AwardWorker.perform_async(@current_user.id, star.id, star.class.name, 2, 1, 'punch', :award)
    CoreLogger.info(controller: 'Home::Punches', action: 'create', star_id: params[:star_id], current_user: @current_user.try(:id))
    render json: { success: true }
  end
end
