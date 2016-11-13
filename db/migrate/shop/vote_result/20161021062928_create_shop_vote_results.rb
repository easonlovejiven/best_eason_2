class CreateShopVoteResults < ActiveRecord::Migration
  def change
    create_table :shop_vote_results do |t|
      t.integer :shop_vote_option_id
      t.integer :user_id
      t.integer :resource_id
      t.string :resource_type
      t.boolean :active, null: false, default: true
      t.timestamps null: false
    end
    add_index :shop_vote_results, :user_id, name: 'by_user_id'
    add_index :shop_vote_results, :shop_vote_option_id, name: 'by_option_id'
    add_index :shop_vote_results, :resource_id, name: 'by_resource_id'
  end
end
