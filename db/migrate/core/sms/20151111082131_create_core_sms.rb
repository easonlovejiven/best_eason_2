class CreateCoreSms < ActiveRecord::Migration
  def change
    create_table :core_smss do |t|
    	t.integer  :editor_id
    	t.integer  :trade_id
    	t.integer  :costumer_id
    	t.string   :phone
    	t.text     :content
    	t.text     :remark
    	t.boolean  :success, default: false, null: false
    	t.boolean  :active, default: true,  null: false
	 	t.integer  :lock_version, default: 0, null: false
    	t.datetime :send_at
    	t.integer  :user_id
      	t.timestamps null: false
    end
  end
end
