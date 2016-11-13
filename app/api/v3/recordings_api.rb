module V3
  class RecordingsApi < Grape::API

    format :json

    before do
      check_sign
    end

    params do
      requires :uid, type: Integer
      requires :genre, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :search_recordings do
      return fail(0, "参数错误") unless params[:genre].present? && %w(all star user).include?(params[:genre])
      return fail(0, "用户不存在!") unless @current_user.present?
      recordings = @current_user.recordings.active.where(genre: params[:genre]).order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
      ret = { data: { recordings: recordings.as_json } }
      success(ret)
    end

    get :hot_records do
      records = Core::HotRecord.order(position: :desc).select("id, name").limit(10)
      success(data: { hot_records: records.as_json })
    end

    params do
      requires :uid, type: Integer
      requires :genre, type: String
    end
    delete :destory_recordings do
      return fail(0, "参数错误") unless params[:genre].present? && %w(all star user).include?(params[:genre])
      @current_user.recordings.map(&:destroy_softly)
      success({data: true})
    end

    params do
      requires :keyword, type: String
      optional :action, type: String
    end
    get :search do
      keyword = params[:keyword].to_s.strip
      return fail(0, "参数不能为空") if keyword.blank?
      tasks = Shop::Task.search keyword, where: {active: true, published: true}, fields: [:title, :star_names], order: {created_at: :desc}
      shop_tasks = Shop::Task.search keyword, fields: [:title, :star_names], where: {active: true, published: true, category: "task"}, order: {created_at: :desc}
      welfare_tasks = Shop::Task.search keyword, fields: [:title, :star_names], where: {active: true, published: true, category: "welfare"}, order: {created_at: :desc}
      stars = Core::Star.search keyword, where: {active: true, published: true}, fields: [:name]
      users = Core::User.where("id != #{@current_user.id}").search keyword, where: {active: true}, order: {created_at: :desc}
      orgs_count = Core::User.where("id != #{@current_user.id}").search(keyword, where: {active: true, identity: "organization"}).total_count
      experts_count = Core::User.where("id != #{@current_user.id}").search(keyword, where: {active: true, identity: "expert"}).total_count
      users_count = Core::User.where("id != #{@current_user.id}").search(keyword, where: {active: true, identity: "common"}).total_count

      if params[:action] == 'all' || params[:from_client] == 'iOS'
        recording = Core::Recording.find_or_initialize_by(name: keyword, user_id: @current_user.id, genre: 'all')
        recording.active = true
        recording.count += 1 if recording.id
        recording.save
      end

      res = {
        count: tasks.total_count + stars.total_count + users.total_count,
        tasks_count: shop_tasks.total_count,
        welfares_count: welfare_tasks.total_count,
        stars_count: stars.total_count,
        orgs_count: orgs_count,
        experts_count: experts_count,
        users_count: users_count
      }
      success({ data: res })
    end

    params do
      requires :keyword, type: String
      requires :category, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :search_list do
      keyword = params[:keyword].to_s.strip
      return fail(0, "参数不能为空") if keyword.blank?
      @stars = Core::Star.search @keyword, where: {active: true, published: true}, page: params[:page] || 1, per_page: params[:per_page] || 10
      @users = Core::User.where("id != #{@current_user.id}").search @keyword, where: {active: true} , order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
      case params[:category].to_s
      when 'task', 'welfare'
        if params[:category] == 'task'
          tasks = Shop::Task.search keyword, fields: [:title, :star_names], where: {active: true, published: true, category: "task"}, order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        elsif params[:category] == 'welfare'
          tasks = Shop::Task.active
          tasks = tasks.where(shop_type: ['Welfare::Letter', 'Welfare::Voice']) unless version_compare
          tasks = tasks.search keyword, fields: [:title, :star_names], where: {active: true, published: true, category: "welfare"}, order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        else
          tasks = Shop::Task.search keyword, where: {active: true, published: true}, fields: [:title, :star_names], order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        end

        res = {
          count: tasks.total_entries,
          tasks: tasks.map do |task|
            tmp_data = {
              id: task.id,
              pic: task.list_pic,
              shop_type: task.shop_type,
              shop_id: task.shop_id,
              title: task.title,
              free: task.free,
              participator: task.participants,
              created_at: task.created_at.to_s(:db),
              share_obi: "分享再得1 O!元",
              buy_obi: task.category == 'task' ? '参与得价格10%的O!元' : '需花费20 O!元'
            }
            case task.shop_type
            when 'Shop::Subject'
              tmp_data.update(participator: Redis.current.get("subject:#{task.shop_id}:read_subject_participator").to_i)
            when 'Shop::Media'
              tmp_data.update(participator: Redis.current.get("media:#{task.shop_id}:read_subject_participator").to_i)
            end
            tmp_data
          end
        }
      when 'star'
        stars = Core::Star.search keyword, where: {active: true, published: true}, fields: [:name], order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        res = {
          count: stars.total_entries,
          stars: stars.map do |star|
            {
              id: star.id,
              pic: star.app_picture_url,
              name: star.name,
              follower_count: star.fans_total,
              friendship: (@current_user.following?(star) ? 1 : 0),
            }
          end
        }
      when 'org', 'expert', 'user'
        if params[:category] == 'org'
          users = Core::User.where("id != #{@current_user.id}").search keyword, where: {active: true, identity: "organization"}, order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        elsif params[:category] == 'expert'
          users = Core::User.where("id != #{@current_user.id}").search keyword, where: {active: true, identity: "expert"}, order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        elsif params[:category] == 'user'
          users = Core::User.where("id != #{@current_user.id}").search keyword, where: {active: true, identity: "common"}, order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        else
          users = Core::User.where("id != #{@current_user.id}").search keyword, where: {active: true}, order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 10
        end

        res = {
          count: users.total_entries,
          users: users.map do |user|
            {
              id: user.id,
              name: user.name,
              pic: user.app_picture_url,
              friendship: @current_user.friendship[user.follow_key].to_i,
              follow_count: user.follow_count,
              followers_count: user.followers_count
            }
          end
        }
      end
      success({ data: res })
    end
  end
end
