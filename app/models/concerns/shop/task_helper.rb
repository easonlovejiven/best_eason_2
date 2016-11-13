module Shop
  module TaskHelper
    extend ActiveSupport::Concern

    included do |base|
      after_create :create_shop_task
      # after_create :create_milestone
      after_update :destroy_shop_task
      after_update :update_shop_task
    end

    #创建总任务
    def create_shop_task
      return if shop_task
      star_list = (JSON.parse(self.star_list.to_s) || {}).reject {|v| v.blank?}
      task = Shop::Task.new(title: title.gsub(/\r|\n|\#/, ""), user_id: user_id, shop_id: id, star_list: star_list)
      task.shop_type = self.class.name
      task.description = self.description if self.respond_to?(:description)
      task.creator_id = self.creator_id if self.respond_to?(:creator_id)
      task.guide = self.guide if self.respond_to?(:guide)
      task.category = task.shop_type.match(/Welfare/) ? "welfare" : 'task'
      task.free = self.respond_to?(:free) && free
      task.created_at = task.shop_type.match(/Letter|Voice|Paper|Topic|Media|Subject/) ? Time.now.to_s(:db) : self.try(:sale_start_at)
      task.created_time = self.created_at
      if task.shop_type == "Welfare::Product" || task.shop_type == "Welfare::Event"
        task.expired_at = self.try(:end_at) || self.try(:sale_end_at)
      else
        task.expired_at = task.shop_type.match(/Letter|Voice|Paper|Topic|Media|Subject/) ? nil : (self.try(:sale_end_at) || self.try(:end_at))
      end
      task.pic = self.cover_pic
      task.published = true if task.shop_type.match(/Voice/)
      if task.save
        if star_list.size > 0
          default_sql = "INSERT INTO `shop_task_stars` (`shop_task_id`, `core_star_id`, `created_at`, `updated_at`)
            VALUES #{star_list.map {|p| "('#{task.id}', #{p}, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" }.join(",") };"
          Shop::TaskStar.connection.execute(default_sql)
          star_names = star_list.map{|l| Core::Star.find_by(id: l).name}.join(",")
          task.update(star_names: star_names)
          task.shop.update(star_list: star_list)
        end
        if task.shop_type.match(/Voice/)
          TaskWorker.perform_async(task.id, 'create', (JSON.parse(star_list.to_s) || {}).reject{|v| v.blank? } )
        end
      end
    end

    def update_shop_task
      return unless shop_task.changed? || self.active
      star_list = (JSON.parse(self.star_list.to_s) || {}).reject {|v| v.blank?}.map{|i| i.to_i}
      shop_task.attributes = {title: title.gsub(/\r|\n|\#/, ""), user_id: user_id, star_list: star_list}
      shop_task.description = self.description if self.respond_to?(:description)
      shop_task.free = self.respond_to?(:free) && free
      shop_task.created_at = self.try(:sale_start_at) if self.try(:sale_start_at)
      if shop_task.shop_type == "Welfare::Product" || shop_task.shop_type == "Welfare::Event"
        shop_task.expired_at = self.try(:end_at) || self.try(:sale_end_at)
      else
        shop_task.expired_at = shop_task.shop_type.match(/Letter|Voice|Paper|Topic|Media|Subject/) ? nil : (self.try(:sale_end_at) || self.try(:end_at))
      end
      # shop_task.pic = self.cover_pic
      if shop_task.save
        if self.star_list_changed?
          ex_star_list = Shop::Task.connection.execute(self.shop_task.core_stars.select("id").to_sql).to_a.map{|i| i.first}
          add_list = star_list - ex_star_list
          del_list = ex_star_list - star_list
          task = self.shop_task

          if add_list.length > 0
            default_sql = "INSERT INTO `shop_task_stars` (`shop_task_id`, `core_star_id`, `created_at`, `updated_at`)
              VALUES #{add_list.map {|p| "('#{self.shop_task.id}', #{p}, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" }.join(",")};"
            Shop::TaskStar.connection.execute(default_sql)
            task.update(star_names: task.star_names+','+Core::Star.where(id: add_list).map(&:name).join(","))
          end

          if del_list.length > 0
            Shop::TaskStar.where(shop_task_id: shop_task.id, core_star_id: del_list).each do |s|
              s.delete
            end
            task.update(star_names: task.star_names.delete(Core::Star.where(id: del_list).map(&:name).join("")))
          end
          if add_list.length > 0 || del_list.length > 0
            TaskWorker.perform_async(shop_task.id, 'update', add_list, del_list) if shop_task.published #&& shop_task.published_changed?
          end
        else
          TaskWorker.perform_async(shop_task.id, 'pic')
        end
        Rails.cache.delete("#{self.class.name}_#{self.id}")
  			Rails.cache.delete("shop_task_#{self.class.name}_#{self.id}")
      end
    end

    def destroy_shop_task
      return if self.active
      star_ids = (JSON.parse(star_list.to_s) || {}).reject{|v| v.blank? }
      TaskWorker.perform_async(shop_task.id, 'destroy', star_ids)
      shop_task.destroy_softly
    end

    #发布任务存入里程碑
    def create_milestone
      #{ "2016-01" => [ {}, {}, {} ] }
      if Redis.current.get("User:Milestone:#{user_id}").present?
        milestone = JSON.parse(Redis.current.get("User:Milestone:#{user_id}"))
        time = Time.now.strftime("%Y-%m").to_s
        if milestone['time']
          stone_arr = milestone['time'].push({ 'type' => 'sign', 'title' => '注册了Q!what~', 'created_at' => Time.now.strftime("%Y-%m-%d"), 'pic_url' => picture_url })
          milestone.update({ time => stone_arr })
          Redis.current.set("User:Milestone:#{user_id}", milestone)
        else
          Redis.current.set("User:Milestone:#{user_id}", milestone.merge!({ time => [ { 'type' => self.shop_type,
            'action' => 'published_task',
            'title' => 'title',
            'pic_url' => self.cover_pic,
            'user_id' => self.user_id,
            'user_name' => self.user.name,
            'user_pic' => self.user.picture_url,
            'empirical_value' => '经验值同花费金额',
            'obi' => 'O!元为花费金额的1%',
            'participator' => 0 ,
            'created_at' => Time.now.strftime("%Y-%m-%d").to_s,
            } ] }))
        end
      else
        Redis.current.set("User:Milestone:#{user_id}", { time => [ { 'type' => 'sign', 'title' => '注册了Q!what~', 'created_at' => Time.now.strftime("%Y-%m-%d").to_s, 'pic_url' => picture_url } ] })
      end
    end

    def update_shop_task_star
      return unless self.star_list_changed? || active
      star_list = JSON.parse(self.star_list).reject {|v| v.blank?}.map{|i| i.to_i}
      ex_star_list = Shop::Task.connection.execute(self.shop_task.core_stars.select("id").to_sql).to_a.map{|i| i.first}
      add_list = star_list - ex_star_list
      del_list = ex_star_list - star_list

      if add_list.length > 0
        default_sql = "INSERT INTO `shop_task_stars` (`shop_task_id`, `core_star_id`, `created_at`, `updated_at`)
          VALUES #{add_list.map {|p| "('#{self.shop_task.id}', #{p}, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" }.join(",")};"
        Shop::TaskStar.connection.execute(default_sql)

      end
      if del_list.length > 0
        Shop::TaskStar.where(id: [del_list]).delete_all
      end
      if add_list.length > 0 || del_list.length > 0
        TaskWorker.perform_async(shop_task.id, 'update', add_list, del_list)
      end
      return true
    end

    # 真实参与人数数据
    def task_participator
      case self.class.to_s
      when 'Shop::Event', 'Shop::Product', 'Shop::Funding', 'Welfare::Event', 'Welfare::Product'
        self.ticket_types.map{|t| t.participator.value }.sum
      else
        self.participator.value
      end
    end

  end
end
