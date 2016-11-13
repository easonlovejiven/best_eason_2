class AddIsEachLimitToShopTicketTypes < ActiveRecord::Migration
  def change
    add_column :shop_ticket_types, :is_each_limit, :boolean
    add_column :shop_ticket_types, :each_limit, :integer
  end
end
