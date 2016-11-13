class AddColumnOrderNoToExpens < ActiveRecord::Migration
  def change
    add_column :core_expens, :order_no, :string
    add_index :core_expens, :order_no, name: 'by_order_no'
  end
end
