class CreateCoreMobileCode < ActiveRecord::Migration
  def change
    create_table :core_mobile_codes do |t|
    	t.string :mobile
    	t.string :code
    	t.integer :end_time
      t.string :kind
      t.timestamps null: false
    end
    add_index :core_mobile_codes, :mobile, name: 'by_mobile'
  end
end
