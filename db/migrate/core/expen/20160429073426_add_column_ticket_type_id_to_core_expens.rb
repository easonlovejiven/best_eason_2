class AddColumnTicketTypeIdToCoreExpens < ActiveRecord::Migration
  def change
    add_column :core_expens, :shop_ticket_type_id, :integer
    add_column :core_expens, :quantity, :integer
  end
end
