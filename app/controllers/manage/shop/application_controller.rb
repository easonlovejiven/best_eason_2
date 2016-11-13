class Manage::Shop::ApplicationController < Manage::ApplicationController
  def search_star
    @stars = Core::Star.search(params[:name][:term], {where: {active: true, published: true}, fields: [:name]}).map{|u| {"id" => u.id, "name" => u.name}}
    render json: {stars: @stars}
  end

  def get_star
    @stars = if params[:identity]
      identity = Core::Identity.find params[:id]
      Core::Star.where(id: JSON.parse(identity.related_ids.to_s)).as_json
    else
      Shop::Task.find_by(id: params[:id]).core_stars.as_json
    end
    render json: {stars: @stars}
  end

  def get_orgs
    @users = Core::User.search(params[:name][:term], {where: {identity: 'organization', active: true}, fields: [:name]}).map{|u| {"id" => u.id, "name" => u.name}}
    render json: {stars: @users}
  end

  def search_fans
    @users = Core::User.search(params[:name][:term], {where: {identity: 'expert', active: true}, fields: [:name]}).map{|u| {"id" => u.id, "name" => u.name}}
    render json: {stars: @users}
  end

  def get_fans
    ids = Core::Star.active.find_by(id: params[:id]).tries(:related_ids).to_s
    ids = JSON.parse(ids).to_a.reject(&:blank?).map(&:to_i)
    @users = Core::User.active.where(identity: 1, id: ids).as_json
    render json: {stars: @users}
  end

  def search_freight_templates
    # @templates = Shop::FreightTemplate.active.where("name LIKE ?", "%#{params[:name][:term]}%").select("id, name").as_json
    @templates = {}
    render json: {stars: @templates}
  end

  def get_freight_templates
    @templates = Shop::FreightTemplate.find_by(id: params[:id]).as_json
    render json: {stars: @templates}
  end

end
