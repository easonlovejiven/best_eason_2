class AddColumnOwhat2IdToCoreConnections < ActiveRecord::Migration
  def change
    add_column :core_connections, :owhat2_id, :integer
  end
end
