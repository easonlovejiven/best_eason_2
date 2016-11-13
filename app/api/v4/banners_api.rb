module V4
  class BannersApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      requires :position, type: String
    end
    get :banners do
      return fail(0, "参数错误") unless params[:position].present? && %w(home hot).include?(params[:position])
      banners = Core::Banner.effective.phone
      banners = if params[:position] == 'home'
        banners.where(position: ['home','find'])
      else
        banners.where(position: 'hot')
      end
      banners = banners.order_sequence.select('id, title, pic2, link, template, template_id').limit(Core::Banner::SEQUENCE_LIMIT)
      return success({ data: { banners: [{
        "id"=> 0,
        "title"=> "default",
        "pic"=> Core::Banner::DEFAULT_PICTURE,
        "link"=> "",
        "template"=> "",
        "template_id"=> ""
      }]}}) if banners.blank? && params[:position] == 'home'
      success({ data: { banners: banners.map{|banner| {id: banner.id,title: banner.title,pic: banner.pic2_url,link: banner.link,template: banner.template,template_id: banner.template_id} }.as_json } })
    end
  end
end
