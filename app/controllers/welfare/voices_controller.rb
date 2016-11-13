class Welfare::VoicesController < Home::ApplicationController
  def show
    return redirect_to '/' unless params[:id].present?
    @voice = Welfare::Voice.find_by(id: params[:id])
    @user = Core::User.where(id: (@voice.user_id || @voice.creator_id)).first
  end

  def buy
    return redirect_to '/', alert: "该任务还未发布" unless params[:id].present?
    voice = Welfare::Voice.find_by(id: params[:id])
    if @current_user.id != voice.user_id
      complete = voice.shop_task.task_state["#{voice.class.to_s}:#{@current_user.id}"].to_i > 0
      raise "O!元不足" unless complete || @current_user.obi >= 5
      voice.shop_task.payment_obi(@current_user, status: :complete) unless complete
      CoreLogger.info(controller: "Welfare::Voices", action: 'buy', voice_id: voice.try(:id), current_user: @current_user.try(:id)) unless complete
    end
    render json: { success: true }
  end
end
