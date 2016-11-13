class AddFeeDefaultToShopTicketTypes < ActiveRecord::Migration
  def change
    change_column :shop_ticket_types, :fee, :decimal, :precision => 8, :scale => 2, default: 10.0
  end
end
