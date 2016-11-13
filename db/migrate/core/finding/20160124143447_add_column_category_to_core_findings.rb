class AddColumnCategoryToCoreFindings < ActiveRecord::Migration
  def change
    add_column :core_findings, :category, :string
  end
end
