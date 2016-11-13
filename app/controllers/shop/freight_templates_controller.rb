class Shop::FreightTemplatesController < Shop::ApplicationController

  def new
    @template = Shop::FreightTemplate.new
  end

  def create
    @template = Shop::FreightTemplate.new(shop_freight_template_params)
    if @template.save
      CoreLogger.info(controller: "Shop::FreightTemplates", action: 'create', template_id: @template.try(:id), current_user: @current_user.try(:id))
      render '/shop/shared/_step4'
    else
      render :new
    end
  end

  def index
    @templates = Shop::FreightTemplate.by_user(@current_user.id)
  end

  def show
    @template = Shop::FreightTemplate.find_by(id: params[:id])
  end

  private

  def shop_freight_template_params
    params.require(:shop_freight_template)
      .permit(:id, :name, :user_id, :start_position, :user_type, freights_attributes: %w{ freight_template_id start_position destination frist_item id reforwarding_item first_fee reforwarding_fee id_delivery} )
  end

end
