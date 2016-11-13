class ChangeColumnFeeToShopTicketTypes < ActiveRecord::Migration
  def change
    change_column :shop_ticket_types, :fee, :decimal, :precision => 8, :scale => 2, default: 0.0
    change_column :shop_ticket_types, :original_fee, :decimal, :precision => 8, :scale => 2, default: 0.0
  end
end
