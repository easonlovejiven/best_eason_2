class CreateCoreTaskAwards < ActiveRecord::Migration
  def change
    create_table :core_task_awards do |t|
      t.integer :user_id
      t.integer :task_id
      t.string :task_type
      t.integer :empirical_value, default: 0
      t.integer :obi, default: 0  #o元
      t.boolean :active, default:true
      t.string :from

      t.timestamps null: false
    end
  end
end
