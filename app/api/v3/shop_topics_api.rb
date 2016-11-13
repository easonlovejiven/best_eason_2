# encoding:utf-8
module V3
  class ShopTopicsApi < Grape::API
    format :json

    before do
      check_sign
    end

    desc "话题/新鲜事详情页"
    params do
      requires :id, type: Integer
      requires :uid, type: Integer
    end
    get :shop_topic do
      topic = Shop::Topic.active.find_by(id: params[:id])
      task = Shop::Task.where(shop_id: params[:id], shop_type: "Shop::Topic" ).first
      return fail(0, "该话题不存在") unless topic && task.is_available?
      stars = task.core_stars.select("core_stars.id, core_stars.name, core_stars.published").as_json
      topic = topic.as_json.merge!({
        shop_task_id: task.id,
        participator: task.participants,
        stars: stars,
        pic: topic.cover_pic,
        is_completed: (task.task_state["#{topic.class.to_s}:#{params[:uid]}"].to_i > 0),
        share_url: Rails.application.routes.url_helpers.shop_topic_url(params[:id])
      })
      ret = {data: topic}
      success(ret)
    end

    desc "发布话题/新鲜事"
    params do
      requires :title, type: String
      requires :description, type: String
      requires :key, type: String
      requires :is_share, type: Boolean
      requires :uid, type: Integer
      requires :star_list, type: String
    end
    post :create_shop_topic do
      topic = Shop::Topic.new(params_hash)
      if topic.save
        AwardWorker.perform_async(@current_user.id, topic.id, topic.class.name, 4, 2, 'self', :award )
        ret = {data: true}
        CoreLogger.info(logger_format(api: "create_shop_topic", topic_id: topic.try(:id) ))
        success(ret)
      else
        fail(0, '发布新鲜事失败')
      end
    end

    desc "发布动态"
    params do
      requires :content, type: String
      requires :uid, type: Integer
      requires :shop_topic_id, type: Integer
      optional :pictures_attributes, type: Hash do
        optional :pictureable_id, type: Integer
        optional :pictureable_type, type: String
        optional :key, type: String
        optional :user_id, type: Integer
      end
      optional :videos_attributes, type: Hash do
        optional :video_id, type: Integer
        optional :video_type, type: String
        optional :key, type: String
        optional :user_id, type: Integer
      end
    end
    post :create_shop_dynamic do
      return fail_msg(0, '该用户不存在') if @current_user.blank?
      @current_user.create_dynamic_lock.lock do
        topic = Shop::Topic.find_by(id: params[:shop_topic_id])
        return fail(0, "该话题不存在") unless topic && topic.try(:shop_task).try(:is_available?)
        return fail(0, "您发布的动态不能超过3条！") if topic.topic_dynamic_state["#{params[:uid]}"].to_i >= 3
        d = Shop::TopicDynamic.new(params_hash)
        if d.save
          size = Shop::TopicDynamic.where(user_id: params[:uid]).where("created_at > ? ", Time.now.beginning_of_day).size
          AwardWorker.perform_async(@current_user.id, d.id, d.class.name, 4, 2, 'create_topic_dynamic', :award )
          CoreLogger.info(logger_format(api: "create_shop_dynamic", topic_dynamic_id: d.try(:id) ))
          success({data: size})
        else
          fail(0, '创建动态失败')
        end
      end
    end

    desc "赞动态"
    params do
      requires :uid, type: Integer
      requires :dynamic_id, type: Integer
    end
    post :like_shop_dynamic_comment do
      dynamic = Shop::TopicDynamic.find_by(id: params_hash['dynamic_id'])
      topic = dynamic.topic
      @list = Redis::List.new "shop_topic_dynamic_#{params_hash['dynamic_id']}_likes"
      return fail(0, '你已经赞过') if @list.values.include?(params[:uid].to_s)
      if dynamic.update(like_count: dynamic.like_count+1)
        topic.topic_like_count.increment
        @list << params[:uid]
        AwardWorker.perform_async(@current_user.id, dynamic.id, dynamic.class.name, 1, 0, 'self', :award )
        AwardWorker.perform_async(dynamic.user_id, dynamic.id, dynamic.class.name, 2, 0, 'other', :award )
        CoreLogger.info(logger_format(api: "like_shop_dynamic_comment", dynamic_id: dynamic.try(:id) ))
        success({data: dynamic.id})
      else
        fail(0, '赞动态更新失败')
      end
    end

    desc "转发动态"
    params do
      requires :uid, type: Integer
      requires :dynamic_id, type: Integer
    end
    post :forward_shop_dynamic_comment do
      dynamic = Shop::TopicDynamic.find_by(id: params_hash[:dynamic_id])

      if dynamic.update(like_count: dynamic.foward_count+1)
        @list = Redis::List.new "shop_topic_dynamic_#{params_hash[:dynamic_id]}_forwards"
        @list << params_hash[:user_id]
        CoreLogger.info(logger_format(api: "forward_shop_dynamic_comment", dynamic_id: dynamic.try(:id) ))
        success({data: dynamic.id})
      else
        fail(0, '转发动态更新失败')
      end
    end

    desc "创建动态评论"
    params do
      requires :content, type: String
      requires :uid, type: Integer
      requires :parent_id, type: Integer
      requires :dynamic_id, type: Integer
    end
    post :create_shop_dynamic_comment do
      #更改三个地方的评论数量
      @dynamic = Shop::TopicDynamic.find_by(id: params[:dynamic_id])
      topic = @dynamic.try(:topic)
      return fail(0, "该话题不存在") unless topic.present? && topic.try(:shop_task).try(:is_available?)
      status = ActiveRecord::Base.transaction do
        @comment = Shop::DynamicComment.new(params_hash)
        @comment.parent_id = 0 unless params[:parent_id].present?
        @comment.save
        #如果不是主评论 那么给动态主评论的评论回复数加1
        if params[:parent_id] && params[:parent_id] != 0
          Rails.cache.delete("shop_dynamic_comment_by_parent_id_#{params[:parent_id]}")
          parent_comment = Shop::DynamicComment.find_by(id: params[:parent_id])
          parent_comment.update(seed_count: parent_comment.seed_count+1)
        end
        #给动态的评论数加1
        @dynamic.update(comment_count: @dynamic.comment_count+1)
      end
      if status
        Rails.cache.delete("app_shop_dynamic_comment_#{params[:dynamic_id]}")
        AwardWorker.perform_async(@current_user.id, @comment.id, @comment.class.name, 2, 1, 'self', :award )
        CoreLogger.info(logger_format(api: "create_shop_dynamic_comment", comment_id: @comment.try(:id) ))
        success({data: {user_name: @current_user.name, time: Time.now.to_s(:db)}})
      else
        fail(0, '创建动态评论失败')
      end
    end

    desc "话题列表"
    params do
      requires :uid, type: Integer
      requires :order, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_topics do
      if params[:order] == "time"
        topics = Shop::Topic.active
          .joins("LEFT JOIN core_users ON core_users.id = shop_topics.user_id")
          .select("shop_topics.id, shop_topics.title, shop_topics.description
          , shop_topics.cover1, shop_topics.created_at, core_users.name, core_users.pic")
          .order("created_at DESC")
          .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        # topics = topics.map{ |f| f.as_json.merge!({comment_count: f.topic_comment_count.value, like_count: f.topic_like_count.value, participator: f.participator.value, shop_category: "shop_fundings", reword: "经验值同花费金额；O!元为花费金额的1%"}) } #@counter = Redis::Counter.new('funding_participator_#{f['id']}') @counter.increment @counter.value
        topics = topics.map{ |f| f.as_json.merge!({ participator: f.participator.value, shop_category: "shop_topics", reword: "经验值同花费金额；O!元为花费金额的1%"}) }
      else
        topics = Shop::Topic.active
          .joins("LEFT JOIN core_users ON core_users.id = shop_topics.user_id")
          .select("shop_topics.id, shop_topics.title, shop_topics.description
          , shop_topics.cover1, shop_topics.created_at, core_users.name, core_users.pic")
          .order("created_at DESC")
          .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        topics = topics.map{ |f| f.as_json.merge!({participator: f.participator.value, shop_category: "shop_topics", reword: "经验值同花费金额；O!元为花费金额的1%"}) } #@counte
      end
      ret = {data: {task: topics, count: Shop::Topic.active.count}}
      success(ret)
    end

    desc "动态列表"
    params do
      requires :uid, type: Integer
      requires :topic_id, type: Integer
      requires :order, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_topic_dynamics do
      topic = Shop::Topic.find_by(id: params[:topic_id])
      return fail(0, "该话题不存在") unless topic && topic.try(:shop_task).try(:is_available?)
      uid = params[:uid]
      if params[:order] == "time"
        topic_dynamics = Shop::TopicDynamic.where(shop_topic_id: params[:topic_id])
          .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        count = topic_dynamics.total_entries
        topic_dynamics = topic_dynamics.includes([:user, :pictures]).map.each_with_index do |f, index|
          {
            id: f.id,
            index: (index+1)+(params[:page].present? ? params[:page].to_i-1 : 0 )*(params[:per_page] || 10),
            comment_count: f.comment_count,
            content: f.content,
            like_count: f.like_count,
            foward_count: f.foward_count,
            created_at: f.created_at.to_s(:db),
            user_id: f.user.id,
            name: f.user.name,
            pic: f.user.app_picture_url,
            participator: f.participator.value,
            pictures: f.pictures.as_json,
            dynamic_pictures: f.pictures.size > 1 ? f.pictures.map{|p| p.picture_url + "?imageMogr2/thumbnail/!20p" } : f.pictures.map{|p| p.picture_url + "?imageMogr2/thumbnail/!50p" },
            videos: f.videos.as_json,
            liked: Redis::List.new("shop_topic_dynamic_#{f.id}_likes").values.include?(uid.to_s),
            forwarded: Redis::List.new("shop_topic_dynamic_#{params_hash[:dynamic_id]}_forwards").values.include?(uid.to_s),
            share_url: "#{Rails.application.routes.default_url_options[:host]}/shop/dynamic_comments?dynamic_id=#{f.id}",
          }
        end
      else
        topic_dynamics = Shop::TopicDynamic.where(shop_topic_id: params[:topic_id])
          .order("like_count DESC")
          .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        count = topic_dynamics.total_entries
        topic_dynamics = topic_dynamics.includes([:user, :pictures, :videos]).map.each_with_index do |f, index|
          {
            id: f.id,
            index: (index+1)+(params[:page].present? ? params[:page].to_i-1 : 0 )*10,
            comment_count: f.comment_count,
            content: f.content,
            like_count: f.like_count,
            foward_count: f.foward_count,
            created_at: f.created_at.to_s(:db),
            user_id: f.user.id,
            name: f.user.name,
            pic: f.user.picture_url+"?imageMogr2/thumbnail/!30p",
            participator: f.participator.value,
            pictures: f.pictures.as_json,
            dynamic_pictures: f.pictures.size > 1 ? f.pictures.map{|p| p.picture_url + "?imageMogr2/thumbnail/!20p" } : f.pictures.map{|p| p.picture_url + "?imageMogr2/thumbnail/!50p" },
            videos: f.videos.as_json,
            liked: Redis::List.new("shop_topic_dynamic_#{f.id}_likes").values.include?(uid.to_s),
            forwarded: Redis::List.new("shop_topic_dynamic_#{params_hash[:dynamic_id]}_forwards").values.include?(uid.to_s),
            share_url: "#{Rails.application.routes.default_url_options[:host]}/shop/dynamic_comments?dynamic_id=#{f.id}",
          }
        end
      end
      ret = { data: {task: topic_dynamics, count: count } }
      success(ret)
    end

    desc "动态评论列表"
    params do
      requires :uid, type: Integer
      requires :dynamic_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
    get :shop_dynamic_comments do
      topic = Shop::TopicDynamic.find_by(id: params[:dynamic_id]).try(:topic)
      return fail(0, "该话题不存在") unless topic && topic.try(:shop_task).try(:is_available?)
      comments = Rails.cache.fetch("app_shop_dynamic_comment_#{params[:dynamic_id]}") do
        Shop::DynamicComment
        .joins("LEFT JOIN core_users AS users ON users.id = shop_dynamic_comments.user_id")
        .where(dynamic_id: params[:dynamic_id], parent_id: 0).order("created_at DESC")
        .select("shop_dynamic_comments.id, shop_dynamic_comments.content, shop_dynamic_comments.user_id, shop_dynamic_comments.parent_id, shop_dynamic_comments.dynamic_id, shop_dynamic_comments.created_at, shop_dynamic_comments.updated_at, shop_dynamic_comments.active, users.name, users.pic")
      end.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        all_comments = comments.includes([:user]).map do |c|
          {
            id: c.id,
            content: c.content,
            user_id: c.user_id,
            parent_id: c.parent_id,
            dynamic_id: c.dynamic_id,
            created_at: c.created_at.to_s(:db),
            updated_at: c.updated_at.to_s(:db),
            active: c.active,
            name: c.user.name,
            pic: c.user.picture_url+"?imageMogr2/thumbnail/!30p",
            comments: Rails.cache.fetch("shop_dynamic_comment_by_parent_id_#{c.id}") do
              Shop::DynamicComment.where(parent_id: c.id).includes(:user).map do |d|
                {
                  id: d.id,
                  content: d.content,
                  user_id: d.user_id,
                  parent_id: d.parent_id,
                  dynamic_id: d.dynamic_id,
                  created_at: d.created_at.to_s(:db),
                  updated_at: d.updated_at.to_s(:db),
                  active: d.active,
                  name: d.user.name,
                  pic: d.user.picture_url+"?imageMogr2/thumbnail/!30p",

                }
              end
            end
          }
        end
      ret = {data: {task: all_comments, count: comments.total_entries}}
      success(ret)
    end

  end
end
