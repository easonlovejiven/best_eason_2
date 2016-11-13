class CreateCoreExpens < ActiveRecord::Migration
  def change
    create_table :core_expens do |t|
      t.integer :user_id
      t.references :resource, :polymorphic => true
      t.integer :amount
      t.string :action
      t.string :currency
      t.string :status
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
