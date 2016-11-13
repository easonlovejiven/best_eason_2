class Manage::User < ActiveRecord::Base

  belongs_to :editor, foreign_key: 'id', class_name: "Manage::Editor"
  has_many :exported_orders, as: :user, class_name: "Core::ExportedOrder", dependent: :destroy #导出订单列表
  has_many :freight_templates, as: :user, class_name: "Shop::FreightTemplate", dependent: :destroy #运费模板

  scope :active, -> { where active: true }

  cattr_accessor :manage_fields do
		%w{name login_at birthday gender pic};
	end

	def self.acquire(id)
		record = self.find_by_id(id)
		if !record || record.updated_at < 1.day.ago
			u = Core::User.find_by_id(id)
			(record = self.new; record.id = u.id) unless record
			record.name = u.name
			record.birthday = u.birthday
			record.sex = u.sex
			record.login_at = Time.now
			record.save
		end

		record
	end

	def can?(action, resource)
		return false unless editor.try(:active?)

		resource = resource.scoped.klass if resource.respond_to?(:scoped)
		resource = resource.class if resource.is_a?(ActiveRecord::Base)
		resource = resource.to_s.underscore.gsub('/', '_')
		@roles ||= (editor.roles.active + [editor.role]).uniq.compact
		@roles.map { |role| role.can?(action, resource) }.inject(false, &:|)
	end

	def method_missing_with_privilege(method, *args)
		if m = method.to_s.match(/^can_([^\_]+)_([^\?]+)\??/)
			return self.can?(m[1], m[2])
		end

		method_missing_without_privilege(method, *args)
	end

	alias_method_chain :method_missing, :privilege

	def is_role?(role_name)
		self.editor.role.name.eql?(role_name)
	end
end
