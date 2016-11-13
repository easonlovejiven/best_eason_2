class CreateShopPictures < ActiveRecord::Migration
  def change
    create_table :shop_pictures do |t|
      t.references :pictureable, polymorphic: true
      t.string  :cover
      t.integer :position
      t.string  :key  # 七牛文件直传返回的key(带路径的文件名)
      t.integer :comments_count
      t.integer :cached_votes_total, :default => 0
      t.integer :cached_votes_score, :default => 0
      t.integer :cached_votes_up, :default => 0
      t.integer :cached_votes_down, :default => 0
      t.integer :cached_weighted_score, :default => 0
      t.integer :cached_weighted_total, :default => 0
      t.float   :cached_weighted_average, :default => 0.0

      t.timestamps null: false
    end
    add_index  :shop_pictures, :cached_votes_total
    add_index  :shop_pictures, :cached_votes_score
    add_index  :shop_pictures, :cached_votes_up
    add_index  :shop_pictures, :cached_votes_down
    add_index  :shop_pictures, :cached_weighted_score
    add_index  :shop_pictures, :cached_weighted_total
    add_index  :shop_pictures, :cached_weighted_average
  end
end
