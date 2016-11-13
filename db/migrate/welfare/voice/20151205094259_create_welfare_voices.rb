class CreateWelfareVoices < ActiveRecord::Migration
  def change
    create_table :welfare_voices do |t|
      t.integer :user_id
      t.string :key

      t.timestamps null: false
    end
  end
end
