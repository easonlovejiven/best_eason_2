class Home::HomeController < Home::ApplicationController
  def index
    respond_to do |format|
      format.html do
        @banners =  Rails.cache.fetch("index_page_banners", expires_in: 1.hour) do
          Core::Banner.effective.web.order_sequence.limit(Core::Banner::SEQUENCE_LIMIT).map{|b| {pic: b.pic2_url.to_s, link: b.link}}
        end
        @populars_stars = Rails.cache.fetch("index_page_popular_stars", expires_in: 1.hour) do
          Core::Star.except_omei.published.populars.limit(5).map{|s|{fans_total: s.fans_total, sign: s.sign, app_picture_url: s.app_picture_url.to_s, picture_url: s.picture_url.to_s, id: s.id, name: s.name, participants: s.participants}}
        end
        @populars_identity_2, @populars_identity_1 = Rails.cache.fetch("index_page_users", expires_in: 1.hour) do
          [
            Core::User.active.where(identity: 2).populars.limit(5).map{|u|{id: u.id, picture_url: u.picture_url, app_picture_url: u.app_picture_url, data: u, name: u.name, signature: u.signature, participants: u.participants, followers_count: u.followers_count, follow_count: u.follow_count }},
            Core::User.active.where(identity: 1).populars.limit(5).map{|u|{id: u.id, picture_url: u.picture_url, app_picture_url: u.app_picture_url, data: u, name: u.name, signature: u.signature, participants: u.participants, followers_count: u.followers_count, follow_count: u.follow_count }}
          ]
        end
        @all_tasks, @welfares = Rails.cache.fetch("index_page_tasks", expires_in: 1.hour) do
          welfare_tasks = Shop::Task.includes(:shop).includes(:user).welfares.expired.published.tops.limit(8)
          tasks = Shop::Task.includes(:shop).includes(:user).tasks.expired.published.tops.limit(8)
          [tasks, welfare_tasks].map{|ts| ts.map{|task|{
            shop_type: task.shop_type,
            link_url: task.shop.try(:url),
            shop: task.shop,
            web_pic: task.try(:web_pic),
            free: task.try(:free),
            title: task.try(:title),
            user_name: task.user.name,
            user: task.user
          }}}
        end
        @tasks = @current_user.blank? ? @all_tasks : @current_user.feeds.take(8).tops.includes(:shop).includes(:user).map{|task|{
          shop_type: task.shop_type,
          link_url: task.shop.try(:url),
          shop: task.shop,
          web_pic: task.try(:web_pic),
          free: task.try(:free),
          title: task.try(:title),
          user_name: task.user.try(:name) || "",
          user: task.user
        }}
      end
    end
  end

  def tasks
    respond_to do |format|
      format.json do
        @tasks = Rails.cache.fetch("index_page_tasks_#{(%w(events fundings topics questions subjects media).include? params[:category].to_s) ? params[:category] : "all"}", expires_in: 1.hour) do
          tasks = Shop::Task.includes(:user).includes(:shop).tasks.published.tops
          tasks = tasks.send(params[:category]) if %w(events fundings topics questions subjects media).include? params[:category].to_s
          tasks.limit(8).map do |task|
            {
              id: task.id,
              title: task.title,
              pic: task.web_pic,
              url: task.shop_type == 'Shop::Media' ? task.shop.url : url_for(task.shop),
              completed: task.task_state["#{task.shop_type.to_s}:#{@current_user.try(:id)}"].to_i > 0,
              shared: task.share_state["#{task.shop_type.to_s}:#{@current_user.try(:id)}"].to_i > 0,
              shop_type: task.shop_type,
              is_share: task.tries(:shop, :is_share),
              user: {
                id: task.tries(:user, :id),
                name: task.tries(:user, :name),
                url: task.user && home_user_path(task.user),
                pic: task.tries(:user, :picture_url),
                identity: task.tries(:user, :identity),
                is_login: @current_user.present?
              }
            }
          end
        end
        render json: { tasks: @tasks}
      end
    end
  end

  def welfares
    respond_to do |format|
      format.json do
        @welfares = Rails.cache.fetch("index_page_welfares_#{(%w(event product letter voice).include? params[:category].to_s) ? params[:category] : "all"}", expires_in: 1.hour) do
          welfares = Shop::Task.includes(:user).includes(:shop).welfares.expired.tops
          welfares = welfares.where(shop_type: Shop::Task::CATEGORY[params[:category]]) if %w(event product letter voice).include? params[:category].to_s
          welfares.limit(8).map do |welfare|
            {
              id: welfare.id,
              title: welfare.title,
              pic: welfare.web_pic,
              url: url_for(welfare.shop),
              completed: welfare.task_state["#{welfare.shop_type.to_s}:#{@current_user.try(:id)}"].to_i > 0,
              shop_type: welfare.shop_type,
              user: {
                id: welfare.tries(:user, :id),
                name: welfare.tries(:user, :name),
                url: welfare.user && home_user_path(welfare.user_id),
                pic: welfare.tries(:user, :picture_url),
                identity: welfare.tries(:user, :identity),
                is_login: @current_user.present?
              }
            }
          end
        end
        render json: { tasks: @welfares}
      end
    end
  end

def create_subject_comments
    @subject = Shop::Subject.find_by(id: params[:subject_id])
    @user = Core::User.find_by(id: params[:uid])
    available = @subject.present? && @subject.shop_task.is_available?
    if @user != @current_user || !available || @user.blank? || params[:sign] != check_sign(params)
      respond_to do |format|
        format.html
        format.json { render json:
          {
            error: available ? '您未登录！！！' : "该直播不存在"
          }
        }
      end
    else
      @count = Shop::Comment.where(user_id: params[:uid], task_id: params[:subject_id], task_type: 'Shop::Subject').size
      @total_count = Shop::Comment.where(task_id: params[:subject_id], task_type: 'Shop::Subject').size
      status = ActiveRecord::Base.transaction do
        @comment = Shop::Comment.new({parent_id: 0, user_id: params[:uid], content: params[:content], task_id: params[:subject_id], task_type: 'Shop::Subject'})
        @comment.save
      end
      if status
        AwardWorker.perform_async(params[:uid], @comment.id, @comment.class.name, 2, 1, 'self', :award)
        CoreLogger.info(controller: 'Home::Home', action: 'create_subject_comments', subject_id: @subject.try(:id), comment: @comment.as_json, current_user: @current_user.try(:id))
        respond_to do |format|
          format.html
          format.json { render json:
            {
              status: true,
              data: {
                user_pic: @user.try(:picture_url)+"?imageMogr2/thumbnail/!30p",
                user_name: @user.name,
                identity: @user.identity,
                level: @user.level,
                created_at: @comment.created_at,
                content: @comment.content,
                count: @count,
                total_count: @total_count
              }
            }
          }
        end
      else
        respond_to do |format|
          format.html
          format.json { render json:
            {
              error: '创建直播评论失败'
            }
          }
        end
      end
    end
  end

  def create_dynamic_comments
    @user = Core::User.find_by(id: params[:user_id])
    @dynamic = Shop::TopicDynamic.find_by(id: params[:dynamic_id])
    topic = @dynamic.try(:topic)
    available = topic.present? && topic.try(:shop_task).try(:is_available?)
    if @user != @current_user || @user.blank? || !available || params[:sign] != check_sign(params)
      respond_to do |format|
        format.html
        format.json { render json:
          {
            error: available ? '您未登录！！！' : "该话题不存在"
          }
        }
      end
    else
      @comment = Shop::DynamicComment.new({content: params[:content], user_id: params[:user_id], dynamic_id: params[:dynamic_id], parent_id: params[:parent_id]})
      status = ActiveRecord::Base.transaction do
        @dynamic.update!(comment_count: @dynamic.comment_count+1)
        @comment.save
      end
      if status
        Rails.cache.delete("shop_dynamic_comments_#{params[:dynamic_id]}")
        AwardWorker.perform_async(@current_user.id, @comment.id, @comment.class.name, 2, 1, 'self', :award )
        CoreLogger.info(controller: "Shop::DynamicComments", action: 'create', comment_id: @comment.try(:id), current_user: @current_user.try(:id))
        respond_to do |format|
          format.html
          format.json { render json:
            {
              status: true,
              data: {
                user_pic: @user.try(:picture_url)+"?imageMogr2/thumbnail/!30p",
                user_name: @user.name,
                identity: @user.identity,
                level: @user.level,
                created_at: @comment.created_at,
                content: @comment.content,
                comment_id: @comment.id,
                total_count: @dynamic.comment_count
              }
            }
          }
        end
      else
        respond_to do |format|
          format.html
          format.json { render json:
            {
              error: '创建动态评论失败'
            }
          }
        end
      end
    end
  end

  def create_comments
    @subject = Welfare::Letter.find_by(id: params[:task_id])
    @user = Core::User.find_by(id: params[:uid])
    if @user != @current_user || @subject.blank? || @user.blank? || params[:sign] != check_sign(params)
      respond_to do |format|
        format.html
        format.json { render json:
          {
            error: '该图片福利不存在或者该用户不存在或者验签不过'
          }
        }
      end
    else
      status = ActiveRecord::Base.transaction do
        @comment = Shop::Comment.new({user_id: params[:uid], content: params[:content], task_id: params[:task_id], task_type: params[:task_type], parent_id: (params[:parent_id] && params[:parent_id] != 0) ? params[:parent_id] : 0})
        @comment.save
      end
      if status
        AwardWorker.perform_async(params[:uid], @comment.id, @comment.class.name, 2, 1, 'self', :award)
        respond_to do |format|
          format.html
          format.json { render json:
            {
              error: '创建图片福利评论成功'
            }
          }
        end
      else
        respond_to do |format|
          format.html
          format.json { render json:
            {
              error: '创建图片福利评论失败'
            }
          }
        end
      end
    end
  end

  def welcome

  end

  # 认证用户管理后台
  def mindex

  end

  # 搜索结果页
  def search_result
    @keyword = params[:keyword].to_s.strip
    return if @keyword.blank?
    @tasks = Shop::Task.search @keyword, where: {active: true, published: true}, fields: [:title, :star_names], order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 16
    @stars = Core::Star.search @keyword, where: {active: true, published: true}, fields: [:name], page: params[:page] || 1, per_page: params[:per_page] || 16
    if params[:category] == "fans"
      @users = Core::User.search(@keyword, where: {active: true, identity: "expert"}, page: params[:page] || 1, per_page: params[:per_page] || 16)
      @fans_count = @users.total_entries
    elsif params[:category] == "org"
      @users = Core::User.search(@keyword, where: {active: true, identity: "organization"}, page: params[:page] || 1, per_page: params[:per_page] || 16)
      @org_count = @users.total_entries
    elsif params[:category] == "user"
      @users = Core::User.search(@keyword, where: {active: true, identity: "common"}, page: params[:page] || 1, per_page: params[:per_page] || 16)
      @user_count = @users.total_entries
    else
      @users = Core::User.active.search @keyword, where: {active: true}, order: {created_at: :desc}, page: params[:page] || 1, per_page: params[:per_page] || 16
    end
    @task_count = @tasks.total_entries
    @star_count =  @stars.total_entries
    @users_count = @users.total_entries
    @org_count = Core::User.search(@keyword, where: {active: true, identity: "organization"}).total_count unless params[:category] == "org"
    @fans_count = Core::User.search(@keyword, where: {active: true, identity: "expert"}).total_count unless params[:category] == "fans"
    @user_count = Core::User.search(@keyword, where: {active: true, identity: "common"}).total_count unless params[:category] == "user"
    begin
      if @current_user
        recording = Core::Recording.find_or_initialize_by(name: @keyword, user_id: @current_user.id, genre: 'all')
        recording.active = true
        recording.count += 1 if recording.id
        recording.save
      end
    rescue ActiveRecord::StaleObjectError
      Rails.logger.info "数据搜索表修改重复#{recording = Core::Recording.find_or_initialize_by(name: @keyword, user_id: @current_user.id, genre: 'all')}"
    end
  end

  # 发布成功页面
  def step3

  end


  private

  def authorized?
    true
  end

  def check_sign params
    @web = 'OTjnsYwSZ76IR98'
    data_s = params.map do |k, v|
      next if v.is_a? Hash
      next if v.is_a? Array
      unless  ['route_info', 'method', 'path', 'sign', 'format', 'action', 'controller', 'content'].include?(k)
        "#{k}:#{v.to_s}"
      end
    end.compact.sort.join('&')
    sign = Digest::MD5.hexdigest("#{data_s}#{@web}").downcase
  end
end
