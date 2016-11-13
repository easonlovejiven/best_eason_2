class AddSecondCategoryToShopTicketTypes < ActiveRecord::Migration
  def change
    add_column :shop_ticket_types, :second_category, :string
  end
end
