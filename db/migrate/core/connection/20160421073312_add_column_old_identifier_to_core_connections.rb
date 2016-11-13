class AddColumnOldIdentifierToCoreConnections < ActiveRecord::Migration
  def change
    add_column :core_connections, :old_identifier, :string
  end
end
