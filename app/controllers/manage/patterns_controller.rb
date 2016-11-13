class Manage::PatternsController < Manage::ApplicationController
	# layout -> (controller) { controller.request.xhr? && %w{new show edit}.include?(controller.action_name) ? 'modal' : false }

	# before_action :find_record, except: [:index, :new, :create]

	def index
		render text: '', layout: true and return if controller_name.match(/application/)
		@records = model.default(params).includes(model.send(:reflections).keys)
		# @records = @records.none if !can?(:index, model) && @records.count > 1
	end

	def show
		@record = model.f(id)
		@show = true
		# instance_variable_set "@#{controller_name.singularize}".to_sym, record
	end

	def preview
		@record = model.f(id)
		# instance_variable_set "@#{controller_name.singularize}".to_sym, model.f(id)
	end

	def new
		@record = model.new
		@record.attributes = model.f(id).attributes.slice(*@record.manage_fields) if id
		@show = false
		render :show
	end

	# TODO
	def create
		begin
			@record = model.new
			@record.attributes = params.require(param_key).permit(*@record.manage_fields)
			if @record.respond_to?(:creator_id)
				@record.creator_id = @current_user.id
			end
			ActiveRecord::Base.transaction do
				if @record.save!
					CoreLogger.info(controller: "Manage::#{model}", action: 'create', id: @record.try(:id), current_user: @current_user.try(:id))
					respond_with(@record) do |format|
						format.html { render :show }
						format.js { head :ok, info: '创建成功！' }
					end
				else
					redirect_to :back, alert: "检查一下必填项是否添加，图片是否不符合规格，或者图片没有后缀（jpg,png）,是否重复创建"
				end
			end
		rescue ActionView::MissingTemplate => e
			redirect_to :back, alert: "检查一下必填项是否添加，图片是否不符合规格，或者图片没有后缀（jpg,png）"
		rescue ActiveRecord::RecordNotUnique
			redirect_to :back, alert: "您在创建的时候，不能提交和和之前名字相同的"
		rescue Exception => e
			if @record.class.name == "Core::Star"
				redirect_to :back, alert: "您在创建的时候，有错误#{@record.errors.map{|k, v| v}.join(',')}"
			else
	    	redirect_to :back, alert: "您在创建的时候，有错误#{@record.errors.first.present? ? @record.errors.map{|k, v| v}.join(',') : e}"
			end
		end
  end

	def edit
		@record = model.f(id)
		# instance_variable_set "@#{controller_name.singularize}".to_sym, model.f(id)
		@show = false
		render :show
	end

	def update
		@record = model.f(id)
		@record.attributes = params.require(param_key).permit(*@record.manage_fields)
		if @record.respond_to?(:updater_id)
			@record.updater_id = @current_user.id
		end

		if @record.save
			CoreLogger.info(controller: "Manage::#{model}", action: 'update', id: @record.try(:id), current_user: @current_user.try(:id), updated_date: @record.to_json)
			respond_with(@record) do |format|
				format.html { render :show }
				format.js { head :ok, info: '修改成功！' }
			end
    else
      redirect_to :back, alert: @record.errors.first.last
		end
	end

	def publish
		@record = model.f(id)
		@record.update_attributes(published: true, updater_id: @current_user.id)
		CoreLogger.info(controller: "Manage::#{model}", action: 'publish', id: @record.try(:id), current_user: @current_user.try(:id)) if @record.valid?
		head @record.valid? ? :accepted : :bad_request
	end

	def unpublish
		@record = model.f(id)
		@record.update_attributes(published: false, updater_id: @current_user.id)
		CoreLogger.info(controller: "Manage::#{model}", action: 'unpublish', id: @record.try(:id), current_user: @current_user.try(:id)) if @record.valid?
		head @record.valid? ? :accepted : :bad_reqest
	end

	def delete
		@record = model.f(id)
		instance_variable_set "@#{controller_name.singularize}".to_sym, model.f(id)
		CoreLogger.info(controller: "Manage::#{model}", action: 'delete', id: @record.try(:id), current_user: @current_user.try(:id))
		render template: 'manage/shared/delete'
	end

	def destroy
		@record = model.f(id)
		# @record.attributes = {active: false, updater_id: @current_user.id}
		@record.attributes = {active: false}
		@record.save
		return head :bad_request unless @record.valid?
		CoreLogger.info(controller: "Manage::#{model}", action: 'destroy', id: @record.try(:id), current_user: @current_user.try(:id)) if @record.valid?
		return redirect_to :back, notice: "成功删除！"
	end

	private

	def find_record
		# @record = model.f(id)
		@show = !%w[new edit].include?(params[:action]) && @record.valid?
		# head :not_found, info: '找不到你想要的记录！' if @record.blank?
	end
end
