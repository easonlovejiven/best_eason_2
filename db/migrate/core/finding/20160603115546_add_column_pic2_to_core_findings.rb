class AddColumnPic2ToCoreFindings < ActiveRecord::Migration
  def change
    add_column :core_findings, :pic2, :string
  end
end
