module V3
  class StarsApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      requires :uid, type: Integer
      optional :keyword, type: String
      optional :action, type: String
      optional :order, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :stars_index do
      return fail(0, "用户不存在!") unless @current_user.present?
      stars = Core::Star.published
      keyword = params[:keyword].to_s.strip
      if keyword.present?
        stars = stars.where("name LIKE ?","%#{keyword}%")
        if params[:action].present?
          recording = Core::Recording.find_or_initialize_by(name: keyword, user_id: @current_user.id, genre: 'star')
          recording.active = true
          recording.count += 1 if recording.id
          recording.save
        end
      end
      stars = if params[:order] == 'name'
        conv = Iconv.new("GBK//IGNORE", "utf-8")
        stars.select("id, name, pic, fans_count, followers_user_count, published").sort {|x, y| conv.iconv(x.name) <=> conv.iconv(y.name)}.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      else
        stars.select("id, name, pic, fans_count, followers_user_count, published").populars.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      end
      count = stars.total_entries
      stars = stars.map do |star|
        {
          id: star.id,
          name: star.name,
          pic: star.app_picture_url,
          follower_count: star.fans_total,
          friendship: (@current_user.following?(star) ? 1 : 0),
          auth: star.published
        }
      end
      ret = {data: { stars: stars.as_json, count: count } }
      success(ret)
    end

    params do
      requires :uid, type: Integer
      requires :star_id, type: Integer
    end
    get :star_home do
      star = Core::Star.published.find_by(id: params[:star_id])
      return fail(0, "该明星不存在") unless star
      success(data: {
        star: {
          id: star.id,
          name: star.name,
          sign: star.sign,
          pic: star.picture_url,
          description: star.description,
          friendship: (@current_user.following?(star) ? 1 : 0),
          company: star.company,
          is_punch: @current_user.punches.where(star_id: star.id).is_punch(Time.zone.now.beginning_of_day).present?,
          works: star.works,
          acting: star.acting,
          related_ids: JSON.parse(star.related_ids.to_s).to_a.reject(&:blank?).join(','),
          auth: star.published,
          follower_count: star.fans_total,
          h5_url: "#{Rails.application.routes.default_url_options[:host]}/home/stars/#{star.id}",
        }
      })
    end

    params do
      requires :keyword, type: String
    end
    post :star_create do
      keyword = params[:keyword].to_s.strip
      return fail(0, "名称不能为空") if keyword.blank?
      if star = Core::Star.find_or_create_by(name: keyword)
        CoreLogger.info(logger_format(api: "star_create", star_id: star.try(:id) ))
        success(data: {
          star: {
            id: star.id,
            name: star.name,
            nickname: star.nickname,
            pic: star.picture_url,
            cover: star.cover.try(:url),
            description: star.description,
            company: star.company,
            works: star.works,
            acting: star.acting,
            related_ids: JSON.parse(star.related_ids.to_s).to_a.reject(&:blank?).join(','),
            auth: star.published
          }
        })
      else
        fail(0, "创建失败")
      end
    end

    params do
      requires :uuid, type: Integer
    end
    get :relation_stars do
      stars = Core::Star.find_by_sql("SELECT `core_stars`.id, `core_stars`.name, `core_stars`.pic, `core_stars`.published FROM `core_stars` WHERE `core_stars`.`active` = 1 AND `core_stars`.`id` IN (select  core_star_id from shop_task_stars where shop_task_stars.shop_task_id IN (select id from shop_tasks where shop_tasks.user_id = #{@current_user.id}))")
      stars = stars.map do |star|
        {
          id: star.id,
          name: star.name,
          pic: star.app_picture_url,
          auth: star.published,
          follower_count: star.followers_count,
          friendship: (@current_user.following?(star) ? 1 : 0)
        }
      end
      ret = {data: { stars: stars } }
      success(ret)
    end

    params do
      requires :star_id, type: Integer
    end
    put :star_follow do
      star = Core::Star.find(params[:star_id])
      if !@current_user.following?(star) && @current_user.follow_and_update_cache(star)
        CoreLogger.info(logger_format(api: "star_follow", star_id: params[:star_id] ))
        success(data: { star: { id: star.id, friendship: (@current_user.following?(star) ? 1 : 0) } })
      else
        fail(0, "关注失败")
      end
    end

    params do
      requires :star_id, type: Integer
    end
    put :star_unfollow do
      star = Core::Star.find(params[:star_id])
      return fail(0, "不能取关O妹哦") if star.id == 423
      if @current_user.unfollow_and_update_cache(star)
        CoreLogger.info(logger_format(api: "star_unfollow", star_id: params[:star_id] ))
        success(data: { star: { id: star.id, friendship: (@current_user.following?(star) ? 1 : 0) } })
      else
        fail(0, "取消关注失败")
      end
    end

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :star_followings do
      user = params[:user_id].blank? ? @current_user : Core::User.find(params[:user_id])
      return fail(0, "用户不存在!") unless user.present?
      stars = user.follows_scoped.where(followable_type: "Core::Star").order(updated_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      count = stars.total_entries
      has_next = stars.next_page.to_i > 0
      stars = stars.map(&:followable).compact.map do |s|
        {
          id: s.id,
          name: s.name,
          pic: s.app_picture_url,
          friendship: (@current_user.following?(s) ? 1 : 0),
          followers_count: s.followers_count
        }
      end
      res = { data: { stars: stars, count: count, has_next: has_next} }
      success(res)
    end

    params do
      optional :star_id, type: Integer
    end
    get :star_orgs_and_fans do
      star = Core::Star.find_by(id: params[:star_id])
      users = star.orgs_and_fans.map do |user|
        {
          id: user.id,
          name: user.name,
          role: user.identity,
          pic: user.app_picture_url,
          follow_count: user.follow_count,
          followers_count: user.followers_count,
          participants: user.participants.to_i,
          friendship: @current_user && @current_user.friendship[user.follow_key].to_i
        }
      end
      success({data: { users: users.as_json } })
    end

    params do
      optional :star_id, type: Integer
    end
    get :star_org do
      user = Core::Star.find_by(id: params[:star_id]).try(:org)
      return fail(0, "该明星没设置明星机构") unless user
      data = {
        id: user.id,
        name: user.name,
        pic: user.picture_url,
        follow_count: user.follow_count,
        followers_count: user.followers_count,
        participants: user.participants.to_i
      }
      success({data: data})
    end

    params do
      optional :star_id, type: Integer
      optional :category, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :star_tasks do
      return fail(0, "参数错误") unless %w(welfare task).include?(params[:category])
      star = Core::Star.find_by(id: params[:star_id])
      feeds = star.shop_tasks.where(category: params[:category])
      feeds = feeds.where(shop_type: ['Welfare::Letter', 'Welfare::Voice']) if params[:category] == 'welfare' && !version_compare
      feeds = feeds.published.newests.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      data = {
        count: feeds.total_entries,
        feeds: feeds.map do |feed|
          complete = feed.task_state["#{feed.shop_type}:#{@current_user.try(:id)}"].to_i > 0
          {
            id: feed.id,
            title: feed.title,
            guide: feed.guide,
            pic: feed.list_pic,
            complete: complete,
            obi: feed.category == "welfare" ? 5 : 0,
            shop_id: feed.shop_id,
            shop_type: feed.shop_type,
            free: feed.free,
            created_at: feed.created_at.to_s(:db),
            updated_at: feed.updated_at.to_s(:db),
            stars: feed.core_stars.map do |star|
              {
                id: star.id,
                name: star.name,
                pic: star.app_picture_url
              }
            end,
            user: {
              id: feed.user_id,
              name: feed.tries(:user, :name),
              pic: feed.tries(:user, :app_picture_url)
            }
          }
        end
      }
      success({ data: data })
    end
  end
end
