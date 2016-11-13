class CreateShopVoteOptions < ActiveRecord::Migration
  def change
    create_table :shop_vote_options do |t|
      t.integer :voteable_id
      t.string :voteable_type
      t.string :content
      t.boolean :active, null: false, default: true
      t.integer :user_id
      t.timestamps null: false
    end
    add_index :shop_vote_options, :voteable_id, name: 'by_voteable_id'
    add_index :shop_vote_options, :user_id, name: 'by_user_id'
  end
end
