class CreateShopTicketTypes < ActiveRecord::Migration
  def change
    create_table :shop_ticket_types do |t|
      t.integer :category_id
      t.integer :event_id
      t.integer :ticket_limit #票总数量
      t.boolean :is_limit #是否限购
      t.decimal :original_fee, :precision => 8, :scale => 2#原价
      t.decimal :fee, :precision => 8, :scale => 2 #现价
      t.boolean :is_deleted, default: false

      t.timestamps null: false
    end
  end
end
