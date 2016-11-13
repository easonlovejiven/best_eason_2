class AddIsIncomedToCoreTaskAwards < ActiveRecord::Migration
  def change
    add_column :core_task_awards, :is_income, :boolean, default: true
  end
end
