module V3
  class AdsApi < Grape::API

    format :json

    before do
      check_sign
    end

    get :ad do
      ad = Core::Ad.effective.where(genre: ['all', params[:from_client].to_s.downcase]).last
      if ad
        success(data: {
          id: ad.id,
          title: ad.title,
          pic: ad.picture_url,
          link: ad.link,
          duration: ad.duration,
          version: '3.27',
          ios_url: "http://itunes.apple.com/us/app/id910606347"
        })
      else
        fail(0, "没有广告图")
      end
    end

  end
end
