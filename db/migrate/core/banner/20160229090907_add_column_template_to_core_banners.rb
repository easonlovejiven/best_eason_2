class AddColumnTemplateToCoreBanners < ActiveRecord::Migration
  def change
    add_column :core_banners, :template, :string
    add_column :core_banners, :template_id, :string
  end
end
