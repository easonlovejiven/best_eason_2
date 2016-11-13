class Manage::ApplicationController < ApplicationController
  include ApplicationHelper
  layout "manage/application"
  before_filter :m_login_filter
  respond_to :html, :xml, :json, :xls, :csv, :tsv

  def index
		return render :file => 'manage/manage/editors/login', :layout => false unless @current_user
		return render text: "Do not have permission to view" unless (editor = @current_user.editor) && editor.active?
		return redirect_to params[:redirect] unless params[:redirect].blank?
		render :text => '', :layout => true
	end

	private

  def m_login_filter
    return render text: "<p>系统升级维护中，后台暂停访问。</p><p>如有特殊情况，请与联系客服：4008980812 。</p>" if Redis.current.get("miaosha").present? && Redis.current.get("miaosha") == 'true'
  end

	def authorized?
		@enable_lazyload = !request.xhr?
		@current_user = Manage::User.acquire(@current_user.id) if @current_user
		return true if params[:controller] == 'manage/application' || (@current_user && params[:controller] =~ /\/application/) || params[:controller] == 'manage/manage/editors' && %w[activate_mail].include?(params[:action])
		return redirect_to(manage_root_path) unless @current_user && (editor = @current_user.editor) && editor.active?
		table = params[:controller].sub('manage/','').gsub('/','_').singularize
		# table = {
		# 	'statistic' => 'manage_role',
		# }[table] || table
		action = {
			'new' => 'create',
			'edit' => 'update',
			'browse' => 'show',
			'preview' => 'show',
			'unpublish' => "publish",
			'delete' => 'destroy',
			'export' => 'manage',
			'download' => 'manage',
			'manual_download' => 'manage',
      'sync' => 'manage',
      'accept' => 'manage',
      'reject' => 'manage',
      'cancel' => 'manage'
    }[params[:action]] || params[:action]
    action = 'index' if table == 'core_banner' && params[:action] == 'show_current_order'
    return @current_user.can?(:index, table) || @current_user.can?(:show, table) if action == 'index'
    @current_user.send("can_#{action}_#{table}?")
  end

	def not_authorized
		respond_to do |format|
			# format.html { raise 'Do not have permission to view' }
			format.html { render text: 'Do not have permission to view' }
			format.js   { head :bad_request }
		end
	end

	def export(options = {})
		fields = (options[:records].const_defined?(:EXPORTS) ? options[:records].const_get(:EXPORTS) : {}).stringify_keys[options[:export]]
		fields = fields.map { |field| [field, field] }.to_h if fields.is_a?(Array)
		fields = { id: 'id' }.update(fields.to_h)
		table = [fields.keys.map { |field| options[:records].arel.engine.human_attribute_name(field) }] + options[:records].map { |record| fields.values.map { |field| field.respond_to?(:call) ? field.call(record) : record.respond_to?(field) ? record.send(field) : field } }
	end

	def can?(*argv)
		@current_user && @current_user.respond_to?(:can?) && @current_user.can?(*argv)
	end

	def model
		name = self.class.name
		return if name =~ /ApplicationController$/

		@model ||= name.remove(/^Manage::|Controller$/).singularize.safe_constantize
	end

	def param_key
		model.model_name.param_key
	end

	def id
		@id ||= params[:id].try(:to_i)
	end
end
