class CreateCoreFollows < ActiveRecord::Migration
  def change
    create_table :core_follows do |t|
    	t.references :followable, :polymorphic => true, :null => false
      t.references :follower,   :polymorphic => true, :null => false
      t.boolean :blocked, :default => false, :null => false
      t.timestamps
    end
    add_index :core_follows, ["follower_id", "follower_type"],     :name => "fk_follows"
    add_index :core_follows, ["followable_id", "followable_type"], :name => "fk_followables"
  end
end
