module V3
  class SuggestionsApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      requires :identity, type: Integer
      optional :keyword, type: String
      optional :action, type: String
      optional :order, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :suggestions do
      return fail(0, "参数错误") unless [0, 1, 2].include?(params[:identity].to_i)
      users = Core::User.where(identity: params[:identity])
      keyword = params[:keyword].to_s.strip
      if keyword.present?
        users = users.where("name LIKE ?","%#{keyword}%")
        if params[:action].present?
          recording = Core::Recording.find_or_initialize_by(name: keyword, user_id: @current_user.id, genre: 'user')
          recording.active = true
          recording.count += 1 if recording.id
          recording.save
        end
      end
      users = if params[:order] == 'name'
        conv = Iconv.new("GBK//IGNORE", "utf-8")
        users.select("id, name, position, follow_user_count, followers_user_count, identity, pic").sort {|x, y| conv.iconv(x.name) <=> conv.iconv(y.name)}.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      else
        users.select("id, name, position, follow_user_count, followers_user_count, identity, pic").populars.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      end
      count = users.total_entries
      has_next = users.next_page.to_i > 0
      users = users.map do |user|
        {
          id: user.id,
          name: user.name,
          pic: user.app_picture_url,
          follow_count: user.follow_count,
          followers_count: user.followers_count,
          friendship: @current_user.friendship[user.follow_key].to_i,
          role: user.identity
        }
      end
      ret = { data: {users: users.as_json, count: count, has_next: has_next }}
      success(ret)
    end

    params do
      optional :category, type: String
      optional :order, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :suggestion_tasks do
      is_category = %w(topics fundings events questions subjects media active tasks).include?(params[:category])
      tasks = if is_category
        Shop::Task.tasks.send(params[:category])
      else
        @current_user.feeds.tasks
      end
      tasks_scope = case params[:order]
        when "hot"
          is_category ? tasks.hots : Shop::Task.tasks.where(id: tasks.pluck(:id)).hots
        when "time"
          is_category ? tasks.newests : Shop::Task.tasks.where(id: tasks.pluck(:id)).newests
        else
          tasks.populars
      end
      tasks = tasks_scope.published.select("id, title, guide, category, shop_type, shop_id, pic, created_at, participants, free").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      success(data: {
        count: tasks.total_entries,
        has_next: tasks.next_page.to_i > 0,
        feeds: tasks.map{|a|
          tmp_data = a.as_json.merge!(pic: a.list_pic).update(title: a.try(:title) && a.try(:title).gsub(/\r|\n/, ""))
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
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :order, type: String
    end
    get :suggestion_welfares do
      welfares = Shop::Task.welfares.published
      welfares = welfares.where(shop_type: ['Welfare::Letter', 'Welfare::Voice']) unless version_compare
      welfares_scope = case params[:order]
      when "hot"
        welfares.populars
      when "time"
        welfares.newests
      else
        welfares.tops
      end
      welfares = welfares_scope.select("id, title, description, shop_type, shop_id, guide, pic, user_id, created_at, participants").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      hash = welfares.map do |welfare|
        {
          id: welfare.id,
          title: welfare.title,
          guide: welfare.guide,
          description: welfare.description,
          shop_type: welfare.shop_type,
          shop_id: welfare.shop_id,
          pic: welfare.list_pic,
          participants: welfare.participants,
          complete: welfare.task_state["#{welfare.shop_type.to_s}:#{@current_user.id}"].to_i > 0,
          created_at: welfare.created_at,
          user: {
            id: welfare.user_id,
            name: welfare.tries(:user, :name),
            pic: welfare.tries(:user, :app_picture_url),
            identity: welfare.tries(:user, :identity)
          }
        }
      end
      success(data: {
        count: welfares.total_entries,
        has_next: welfares.next_page.to_i > 0,
        obi: @current_user.obi.to_i,
        feeds: hash.as_json
      })
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :suggestion_task_images do
      images = Shop::TaskImage.published.select("id, category, pic").paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      unless params[:from_client] == 'iOS'
        images = images.map do |i|
          {
            id: i.id,
            category: i.category,
            pic: i.picture_url,
          }
        end
      end
      success(data: { images: images.as_json })
    end

  end
end
