class AddColumnGuideToQaPosters < ActiveRecord::Migration
  def change
    add_column :qa_posters, :guide, :string
    add_column :qa_posters, :is_share, :boolean, default: false
  end
end
