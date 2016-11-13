class Manage::Grant < ActiveRecord::Base
	belongs_to :editor, -> { where active: true }
	belongs_to :role, -> { where active: true }
	belongs_to :creator, -> { where active: true }, class_name: "Manage::Editor", foreign_key: "creator_id"
	belongs_to :updater, -> { where active: true }, class_name: "Manage::Editor", foreign_key: "updater_id"

	scope :active, -> { where active: true }

	# validates_numericality_of :role_id, :editor_id, only_integer: true, message: '必须为数字且不能为空！'
	validates_uniqueness_of :editor_id, :scope => [:active, :role_id], :if => Proc.new { |record| record.active? }, allow_blank: true
	validates_uniqueness_of :role_id, :scope => [:active, :editor_id], :if => Proc.new { |record| record.active? }, allow_blank: true

	# accepts_nested_attributes_for :grants, :reject_if => Proc.new { |attributes| !attributes['id'] && attributes['active'] == '0' }

	cattr_accessor :manage_fields
	self.manage_fields = %w[editor_id role_id]
end
