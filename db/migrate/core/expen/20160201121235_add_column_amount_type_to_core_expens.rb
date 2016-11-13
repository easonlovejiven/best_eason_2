class AddColumnAmountTypeToCoreExpens < ActiveRecord::Migration
  def change
    change_column :core_expens, :amount, :decimal, precision: 8, scale: 2, default: 0.0
  end
end
