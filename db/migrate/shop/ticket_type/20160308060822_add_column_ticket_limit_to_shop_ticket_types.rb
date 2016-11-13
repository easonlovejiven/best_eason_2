class AddColumnTicketLimitToShopTicketTypes < ActiveRecord::Migration
  def change
    change_column :shop_ticket_types, :ticket_limit, :integer, default: 0
    change_column :shop_ticket_types, :each_limit, :integer, default: 0
  end
end
