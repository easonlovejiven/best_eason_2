class AddTaskTypeColumnToShopTicketTypes < ActiveRecord::Migration
  def change
    add_column :shop_ticket_types, :task_type, :string
    rename_column :shop_ticket_types, :event_id, :task_id
  end
end
