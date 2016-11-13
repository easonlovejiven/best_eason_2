class AddColumnTaskIdToCoreExpens < ActiveRecord::Migration
  def change
    add_column :core_expens, :task_id, :integer
  end
end
