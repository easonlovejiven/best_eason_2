module V4
  class FeedsApi < Grape::API
    format :json

    before do
      check_sign
    end

    params do
      optional :mark, type: String
    end
    get :feeds do
      return fail(0, "该用户不存在") unless @current_user.present?
      feeds = if params[:mark].present?
        @current_user.feeds.take(5)
      else
        @current_user.feeds.change.sample(5)
      end

      ret = feeds.map do |feed|
        {
          id: feed.id,
          title: feed.title,
          pic: feed.list_pic,
          shop_type: feed.shop_type,
          free: feed.free,
          shop_id: feed.shop_id,
        }
      end
      success(data: { feeds: ret, obi: @current_user.obi, version: '3.23', ios_url: "http://itunes.apple.com/us/app/id910606347" })
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :all_feeds do
      return fail(0, "该用户不存在") unless @current_user.present?
      feeds = @current_user.feeds.change.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      ret = feeds.map do |feed|
        tmp_data = {
          id: feed.id,
          title: feed.title,
          pic: feed.list_pic,
          shop_type: feed.shop_type,
          free: feed.free,
          shop_id: feed.shop_id,
          participator: feed.tries(:participants, :to_i),
          user_id: feed.user_id,
          created_at: feed.created_at.to_s(:db),
          updated_at: feed.updated_at.to_s(:db),
          is_complete: feed.task_state["#{feed.shop_type.to_s}:#{@current_user.id}"].to_i > 0,
          is_share: feed.share_state["#{feed.shop_type.to_s}:#{@current_user.id}"].to_i > 0,
          share_obi: "分享再得1 O!元",
          buy_obi: feed.category == 'task' ? '参与得O!元' : '需花费5 O!元',
        }
        case feed.shop_type
        when 'Shop::Subject'
          tmp_data.update(participator: Redis.current.get("subject:#{feed.shop_id}:read_subject_participator").to_i)
        when 'Shop::Media'
          tmp_data.update(participator: Redis.current.get("media:#{feed.shop_id}:read_subject_participator").to_i)
        end
        tmp_data
      end
      success(data: { feeds: ret, count: feeds.total_entries})
    end

    params do
      optional :mark, type: String
    end
    get :tasks do
      tasks = Shop::Task.tasks.expired
      tasks = if params[:mark].present?
        tasks.tops.select("id, title, category, shop_type, shop_id, pic, participants, free").limit(4)
      else
        tasks = tasks.today_update(1.month.ago)
        sum = tasks.count/4
        tasks.populars.select("id, title, category, shop_type, shop_id, pic, participants, free").paginate(page: rand(sum-1)+1, per_page: 4)
      end
      success(data: {
        feeds: tasks.map{|a|
          tmp_data = a.as_json.merge!(pic: a.list_pic).update(title: a.title.gsub(/\r|\n/, ""))
          case a.shop_type
          when 'Shop::Subject'
            tmp_data.update(participants: Redis.current.get("subject:#{a.shop_id}:read_subject_participator").to_i)
          when 'Shop::Media'
            tmp_data.update(participants: Redis.current.get("media:#{a.shop_id}:read_subject_participator").to_i)
          end
          tmp_data
        }.as_json,
      })
    end

    params do
      optional :mark, type: String
    end
    get :welfares do
      welfares = Shop::Task.welfares.expired
      welfares = if params[:mark].present?
        welfares.tops.select("id, title, category, shop_type, shop_id, pic, participants, free").limit(4)
      else
        sum = welfares.count/4
        welfares = welfares.populars.select("id, title, category, shop_type, shop_id, pic, participants, free").sample(4)
      end
      success(data: {
        feeds: welfares.map{|a| a.as_json.merge!(pic: a.list_pic).update(title: a.title.gsub(/\r|\n/, ""))}.as_json,
      })
    end
  end
end
