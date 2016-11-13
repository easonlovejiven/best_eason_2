# encoding:utf-8
module V4
  class ShopTopicsApi < Grape::API
    format :json

    before do
      check_sign
    end

    desc "发布投票动态"
    params do
      requires :uid, type: Integer
      requires :shop_topic_id, type: Integer
      requires :title, type: String
      requires :pictures, type: String
      requires :vote_option, type: String
    end
    post :create_dynamic_vote do
      @current_user.create_dynamic_lock.lock do
        topic = Shop::Topic.find_by(id: params[:shop_topic_id])
        return fail_msg(0, "该话题不存在") unless topic && topic.try(:shop_task).try(:is_available?)
        return fail_msg(0, '该用户不存在') if @current_user.blank?
        return fail_msg(0, "您发布的动态不能超过3条！") if topic.topic_dynamic_state["#{params[:uid]}"].to_i >= 3
        pictures = JSON.parse(params[:pictures] || "[]")
        votes = JSON.parse(params[:vote_option] || "[]")
        return fail_msg(0, '参数错误') unless pictures.is_a?(Array) && votes.is_a?(Array)
        dynamic = Shop::TopicDynamic.new({
          shop_topic_id: topic.id,
          content: params[:title],
          user_id: @current_user.try(:id),
          pictures_attributes: pictures.map{|p|{
            key: p.to_s,
            user_id: @current_user.try(:id)
          }},
          vote_options_attributes: votes.map{|v| v.merge({user_id: @current_user.try(:id)})}
        })
        if dynamic.save
          size = Shop::TopicDynamic.where(user_id: params[:uid]).where("created_at > ? ", Time.now.beginning_of_day).size
          AwardWorker.perform_async(@current_user.id, dynamic.id, dynamic.class.name, 4, 2, 'create_topic_dynamic', :award )
          CoreLogger.info(logger_format(api: "create_dynamic_vote", topic_dynamic_id: dynamic.try(:id) ))
          success({data: size})
        else
          fail(0, '创建动态失败')
        end
      end
    end

    desc "用户投票"
    params do
      requires :uid, type: Integer
      requires :vote_id, type: Integer
    end
    post :vote_dynamic do
      return fail_msg(0, '该用户不存在') if @current_user.blank?
      vote_option = Shop::VoteOption.find_by(id: params[:vote_id])
      return fail_msg(0, "该投票选项不存在") unless vote_option.present?
      resource = vote_option.try(:voteable)
      return fail_msg(0, "该动态不存在") unless resource.present?
      topic = resource.try(:topic)
      return fail_msg(0, "该话题不存在") unless topic.present? && topic.try(:shop_task).try(:is_available?)
      vote_result = Shop::VoteResult.new({
        shop_vote_option_id: vote_option.id,
        user_id: @current_user.try(:id),
        resource_id: resource.try(:id),
        resource_type: resource.class.name
      })
      if vote_result.save
        AwardWorker.perform_async(@current_user.id, vote_result.id, vote_result.class.name, 2, 1, 'self', :award )
        CoreLogger.info(logger_format(api: "vote_dynamic", vote_result: vote_result.to_json ))
        success({data: true})
      else
        fail(0, '投票失败')
      end
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
      return fail(0, "该用户不存在") unless @current_user.present?
      uid = params[:uid]
      if params[:order] == "time"
        topic_dynamics = Shop::TopicDynamic.where(shop_topic_id: params[:topic_id])
          .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        count = topic_dynamics.total_entries
        topic_dynamic_vote_results = Hash[Shop::VoteResult.where(resource_id: topic_dynamics.map(&:id),resource_type: "Shop::TopicDynamic", user_id: @current_user.id).group_by(&:resource_id).map{|c, r| [c, r.first.shop_vote_option_id]}]

        topic_dynamic_vote_options = Hash[Shop::VoteOption.where(voteable_id: topic_dynamics.map(&:id),voteable_type: "Shop::TopicDynamic").group_by(&:voteable_id).map{|id, value|[id,{
          active: true,
          is_voted: topic_dynamic_vote_results[id].present?,
          participator: value.map{|c| c.vote_count.to_i}.sum || 0,
          detail: value.map{|d|{
            id: d.try(:id),
            content: d.try(:content),
            voted_count: (d.try(:vote_count) || 0).to_i,
            is_choosed: (topic_dynamic_vote_results[id] || 0) == d.try(:id)
          }}
        }]}]
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
            vote: topic_dynamic_vote_options[f.id] || {activ: false}
          }
        end
      else
        topic_dynamics = Shop::TopicDynamic.where(shop_topic_id: params[:topic_id])
          .order("like_count DESC")
          .paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
        count = topic_dynamics.total_entries
        topic_dynamic_vote_results = Hash[Shop::VoteResult.where(resource_id: topic_dynamics.map(&:id),resource_type: "Shop::TopicDynamic", user_id: @current_user.id).group_by(&:resource_id).map{|c, r| [c, r.first.shop_vote_option_id]}]

        topic_dynamic_vote_options = Hash[Shop::VoteOption.where(voteable_id: topic_dynamics.map(&:id),voteable_type: "Shop::TopicDynamic").group_by(&:voteable_id).map{|id, value|[id,{
          active: true,
          is_voted: topic_dynamic_vote_results[id].present?,
          participator: value.map{|c| c.vote_count.to_i}.sum || 0,
          detail: value.map{|d|{
            id: d.try(:id),
            content: d.try(:content),
            voted_count: (d.try(:vote_count) || 0).to_i,
            is_choosed: (topic_dynamic_vote_results[id] || 0) == d.try(:id)
          }}
        }]}]
        topic_dynamics = topic_dynamics.includes([:user, :pictures]).map.each_with_index do |f, index|
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
            vote: topic_dynamic_vote_options[f.id] || {activ: false}
          }
        end
      end
      ret = { data: {task: topic_dynamics, count: count } }
      success(ret)
    end

  end
end
