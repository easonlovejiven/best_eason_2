module V3
  class BannersApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      requires :position, type: String
    end
    get :banners do
      return fail(0, "参数错误") unless params[:position].present? && %w(home find funding hot).include?(params[:position])
      banners = Core::Banner.effective.phone.old_pics.where(position: params[:position]).order_sequence.select('id, pic, link, template, template_id').limit(Core::Banner::SEQUENCE_LIMIT)
      banners = Core::Banner.published.phone.old_pics.last(1) if banners.blank?
      res = { data: { banners: banners.as_json } }
      success(res)
    end


    get :finding_images do
      findings = Core::Finding.published.select('id, pic, pic2, category, count').limit(4)
      findings = if params[:from_client] == 'iOS' && !version_compare
        findings
      else
        findings.map do |i|
          {
            id: i.id,
            category: i.category,
            pic: version_compare ? i.pic2_url : i.picture_url,
            count: i.count
          }
        end
      end
      success({ data: { findings: findings.as_json } })
    end
  end
end
