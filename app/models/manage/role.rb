class Manage::Role < ActiveRecord::Base
	has_many :grants, -> { where active: true }
	has_many :editors, :through => :grants
	belongs_to :creator, -> { where active: true }, class_name: "Manage::Editor", foreign_key: "creator_id"
	belongs_to :updater, -> { where active: true }, class_name: "Manage::Editor", foreign_key: "updater_id"

	accepts_nested_attributes_for :grants, :reject_if => Proc.new { |attributes| !attributes['id'] && attributes['active'] == '0' }

	validates_uniqueness_of :name, :scope => :active, :if => Proc.new { |record| record.active? }, :allow_blank => true
	validates_associated :grants
	validates_presence_of :name, message: "名称不能为空！"
	scope :active, -> { where active: true }

	RESOURCES = %w{
		statistic
		manage_editor
		manage_role
		manage_grant
		core_user
		core_star
		core_account
		core_keyword
		core_sms
		core_recording
		core_ad
		core_banner
		core_image
		core_finding
		shop_address
		shop_funding
		shop_product
		shop_order
		shop_order_item
		shop_price_category
		shop_ticket_type
		shop_topic
		shop_event
		shop_topic_dynamic
		shop_freight_template
		shop_subject
		shop_task
		shop_task_image
		welfare_paper
		welfare_letter
		shop_funding_order
		core_withdraw_order
		welfare_event
		welfare_product
		core_expen
    core_identity
    shop_media
    core_hot_record
    core_exported_order
    notification_send
    qa_poster
	}

	EXCLUDE_ATTR = %w{id name creator_id description destroyed_at updater_id active lock_version created_at updated_at}

	# index 1
	# show 2
	# create 4
	# update 8
	# destroy 16
	# publish 32
	# manage 64

	AUTHORITY = %w[ index show create update destroy publish manage ]
	AUTHS = 0.upto(AUTHORITY.size-1).map { |i| 1<<i }
	FUNCTIONS = AUTHS.zip(AUTHORITY).to_h
	# FUNCTIONS =  AUTHORITY.zip(AUTHS).to_h


	cattr_accessor :manage_fields, :page_attributes, :nav_attributes
	self.manage_fields = %w[name description grants_attributes] + RESOURCES

	def deletable? #:nodoc: all
		self.grants.empty?
	end

	self.page_attributes = {
		text: %w[ name ],
		text_area: %w[ description ]
	}

	def get_manage_attrs num
		raise 'Invalid digit' if num > AUTHS.inject(0) { |sum, i| sum+=i; sum }
		nums = AUTHS.reverse_each.inject([]) do |a, i|
			a << i and a << (num = num - i) if num >= i
			a
		end
		nums&AUTHS
	end

	def get_attrs num
		FUNCTIONS.slice(*get_manage_attrs(num))
	end

	def can?(action, resource)
		return false unless self.attributes.keys.include?(resource)
		get_attrs(self.send(resource)).values.to_a.include?(action.to_s)
	end

	def functions
		self.attributes.slice!(*EXCLUDE_ATTR).map { |field, num| {field => get_manage_attrs(num)} }
	end

	self.nav_attributes =[

	]
end
