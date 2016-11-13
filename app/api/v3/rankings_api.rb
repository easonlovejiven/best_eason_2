module V3
  class RankingsApi < Grape::API
    format :json

    before do
      check_sign
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :funding_stars_ranking do
      stars = Core::Star.except_omei.published.populars.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      count = stars.total_entries
      stars = stars.map do |star|
        {
          id: star.id,
          name: star.name,
          pic: star.picture_url,
          follower_count: star.fans_total,
          participants: star.participants.to_i,
          sign: star.sign
        }
      end
      success({data: { stars: stars.as_json, count: count } })
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :funding_experts_ranking do
      users = Core::User.active.where(identity: 1).populars.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      count = users.total_entries
      users = users.map do |user|
        {
          id: user.id,
          name: user.name,
          pic: user.picture_url,
          follow_count: user.follow_count,
          followers_count: user.followers_count,
          participants: user.participants.to_i
        }
      end
      success({data: { users: users.as_json, count: count } })
    end
  end
end
