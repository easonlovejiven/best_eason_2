class AddColumnCountToCoreFindings < ActiveRecord::Migration
  def change
    add_column :core_findings, :count, :integer, default: 0
  end
end
