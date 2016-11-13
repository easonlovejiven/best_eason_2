class CreateCoreAreas < ActiveRecord::Migration
  def change
    create_table :core_areas do |t|
      t.string :name
      t.string :ancestry

      t.timestamps null: false
    end
  end
end
