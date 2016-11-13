class CreateCoreWithdrawOrders < ActiveRecord::Migration
  def change
    create_table :core_withdraw_orders do |t|
      t.decimal :amount
      t.integer :tickets_count
      t.string :receiver_name
      t.string :receiver_account
      t.string :bank_name
      t.text :requestor_remark
      t.integer :requested_by
      t.date :requested_at
      t.string :verifier_remark
      t.date :verified_at
      t.integer :verified_by
      t.datetime :cut_off_at
      t.string :mobile
      t.string :email
      t.integer :status
      t.boolean :active

      t.timestamps null: false
    end
  end
end
