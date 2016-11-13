class AddStartAtToWelfareEvents < ActiveRecord::Migration
  def change
    add_column :welfare_events, :start_at, :datetime
    add_column :welfare_events, :end_at, :datetime
    add_column :welfare_products, :start_at, :datetime
    add_column :welfare_products, :end_at, :datetime
  end
end
