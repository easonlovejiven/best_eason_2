class CreateManageRoles < ActiveRecord::Migration
	def change
		create_table :manage_roles do |t|
			t.string  :name
			t.text   :description
			t.integer  :creator_id
			t.integer  :updater_id
			t.datetime :destroyed_at
			t.boolean  :active, default: true, null: false
			t.integer  :lock_version, default: 0,    null: false

			t.integer  :manage_grant, default: 0
			t.integer  :manage_editor, default: 0
			t.integer  :manage_role,  default: 0
			t.integer  :core_account, default: 0
			t.integer  :core_user,    default: 0
			t.integer  :core_keyword, default: 0
			t.integer  :core_sms, default: 0
			t.integer  :shop_address, default: 0
			t.integer  :shop_funding, default: 0
			t.integer  :shop_order, default: 0
			t.integer  :shop_order_item, default: 0
			t.integer  :shop_price_category, default: 0
			t.integer  :shop_product, default: 0
			t.integer  :shop_ticket_type, default: 0

			t.timestamps null: false
		end
	end
end
