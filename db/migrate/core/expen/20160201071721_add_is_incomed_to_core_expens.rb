class AddIsIncomedToCoreExpens < ActiveRecord::Migration
  def change
    add_column :core_expens, :is_income, :boolean, default: false
  end
end
