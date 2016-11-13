class CreateCoreFeedbacks < ActiveRecord::Migration
  def change
    create_table :core_feedbacks do |t|
      t.string :user_id
      t.text :content
      t.timestamps null: false
    end
  end
end
