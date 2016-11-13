class Manage::Core::ApplicationController < Manage::PatternsController
  def search_user
    #认证用户
    @users = Core::User.search(params[:name][:term], {where: {active: true, verified: true}, fields: [:name]}).map{|u| {"id" => u.id, "name" => u.name}}
    render json: {stars: @users}
  end

  def search_user_all
    #所有用户
    @users = Core::User.search(params[:name][:term], {where: {active: true}, fields: [:name]}).map{|u| {"id" => u.id, "name" => u.name}}
    render json: {stars: @users}
  end

  def get_user
    #认证用户
    @users = Core::User.active.where(verified: true).where(id: params[:id]).select("id, name").as_json
    render json: {stars: @users}
  end

  def get_user_all
    #所有用户
    @users = Core::User.active.where(id: params[:id]).select("id, name").as_json
    render json: {stars: @users}
  end
end
