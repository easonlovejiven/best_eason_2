module V3
  class PunchesApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      requires :star_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :punches do
      star = Core::Star.published.find_by(id: params[:star_id])
      return fail(0, "没有该明星") unless star.present?
      punches = @current_user.punches.where(star_id: star.id).select("id, user_id, created_at").order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      success(data: { punches: punches.as_json, count: punches.total_entries })
    end

    params do
      requires :star_id, type: Integer
    end
    post :create_punch do
      star = Core::Star.published.find_by(id: params[:star_id])
      return fail(0, "没有该明星") unless star.present?
      return fail(0, "当天已经打卡") if @current_user.punches.where(star_id: star.id).is_punch(Time.zone.now.beginning_of_day).present?
      return fail(0, "每天只能打卡5次") if @current_user.punches.is_punch(Time.zone.now.beginning_of_day).size > 4
      @current_user.punches.new(star_id: star.id).save
      star.increment!(:participants)
      AwardWorker.perform_async(@current_user.id, star.id, star.class.name, 2, 1, 'punch', :award)
      CoreLogger.info(logger_format(api: "create_punch", star_id: params[:star_id]))
      success(data: true)
    end
  end
end
