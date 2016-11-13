module V3
  class FeedsApi < Grape::API
    format :json

    before do
      check_sign
    end

    params do
      requires :category, type: String
    end
    get :feeds_index do
      return fail(0, "参数错误") unless %w(welfare task).include?(params[:category])
      feeds = @current_user.feeds.change.where(category: params[:category]).published.populars.paginate(page: params[:page] || 1, per_page: params[:per] || 10)
      data = {
        count: feeds.total_entries,
        feeds: feeds.map do |feed|
          {
            id: feed.id,
            title: feed.title,
            guide: feed.guide,
            pic: feed.list_pic,
            free: feed.free,
            created_at: feed.created_at.to_s(:db),
            updated_at: feed.updated_at.to_s(:db),
            stars: feed.core_stars.map do |star|
              {
                id: star.id,
                name: star.name,
                pic: star.picture_url
              }
            end,
            user: {
              id: feed.user_id,
              name: feed.tries(:user, :name),
              pic: feed.tries(:user, :picture_url)
            }
          }
        end
      }
      success({ data: data })
    end

    get :feeds do
      return fail(0, "该用户不存在") unless @current_user.present?
      feeds = @current_user.feeds.take.published.populars
      ret = feeds.map do |feed|
        {
          id: feed.id,
          title: feed.title,
          guide: feed.guide,
          pic: feed.list_pic,
          shop_type: feed.shop_type,
          free: feed.free,
          shop_id: feed.shop_id,
          participator: feed.tries(:participants, :to_i),
          created_at: feed.created_at.to_s(:db),
          updated_at: feed.updated_at.to_s(:db),
          is_complete: feed.task_state["#{feed.shop_type.to_s}:#{@current_user.id}"].to_i > 0,
          is_share: feed.share_state["#{feed.shop_type.to_s}:#{@current_user.id}"].to_i > 0,
          share_obi: "分享再得1 O!元",
          buy_obi: feed.category == 'task' ? '参与得O!元' : '需花费5 O!元',
          user: {
            id: feed.user_id,
            name: feed.tries(:user, :name),
            pic: feed.tries(:user, :app_picture_url),
            identity: feed.tries(:user, :identity)
          }
        }
      end
      success(data: { feeds: ret, obi: @current_user.obi, task_count: Shop::Task.published.today_update(Time.zone.now.beginning_of_day).count, version: '3.26', ios_url: "http://itunes.apple.com/us/app/id910606347" })
    end
  end
end
