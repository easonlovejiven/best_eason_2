class AddIndexByTaskIdAndTaskTypeToShopTicketTypes < ActiveRecord::Migration
  def change
    add_index :shop_ticket_types, ["task_id", "task_type"],     :name => "by_task_id_and_task_type"
  end
end
