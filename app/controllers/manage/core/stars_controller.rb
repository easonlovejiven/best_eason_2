class Manage::Core::StarsController < Manage::Core::ApplicationController
  def index
    render text: '', layout: true and return if controller_name.match(/application/)
    if params["where"].present? && params["where"]["name"]["like"].present?
      query = []
      limit = (params[:per_page] || 10).to_i
      offset = ((params[:page] || 1).to_i - 1) * limit
      query_option = {where: {active: true}, fields: [:name], limit: limit, offset: offset, page: params[:page] || 1}
      query_option[:where] = query_option[:where].merge({id: params[:where][:id]}) if params[:where].present? && params[:where][:id].present?
      query_option[:order] = Hash[[params[:order].split(" ")]] if params[:order].present?
      query << params[:where][:name][:like] if params[:where].present? && params[:where][:name].present? && params[:where][:name][:like].present?
      query << query_option
      @records = model.search(*query)
    else
      @records = @tasks = model.default(params).includes(model.send(:reflections).keys)
    end
  end
end
