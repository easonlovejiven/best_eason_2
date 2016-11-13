class AddColumnActiveToCoreExpens < ActiveRecord::Migration
  def change
    add_column :core_expens, :active, :boolean, default: true
  end
end
