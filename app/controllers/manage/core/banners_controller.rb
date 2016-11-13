class Manage::Core::BannersController < Manage::Core::ApplicationController
  def show_current_order
    genre = (params[:genre].blank? || params[:genre] == 'phone')? 'phone' : 'web'
    @banners = Core::Banner.will_effective.where(genre: genre).order(sequence: :asc).paginate(page: params[:page] || 1, per_page: 20)
  end
end
