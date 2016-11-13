class AddCateToShopTicketTypes < ActiveRecord::Migration
  def change
    add_column :shop_ticket_types, :category, :string
    change_column :shop_ticket_types, :active, :boolean, default: 1
  end
end
