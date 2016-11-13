class Home::WalletsController < Home::ApplicationController

  def index
    if @current_user.verified?
      @rmb_detail = Shop::OrderItem.find_by_sql(
        "SELECT `o`.id, `o`.is_income, `o`.owhat_product_id, `o`.owhat_product_type, `o`.created_at, `o`.payment FROM `shop_order_items` AS `o` WHERE `o`.user_id = #{@current_user.id} AND `o`.status = 2 UNION ALL
         SELECT `f`.id, `f`.is_income, `f`.shop_funding_id, `f`.shop_funding_type, `f`.created_at, `f`.payment FROM `shop_funding_orders` AS `f`  WHERE `f`.user_id = #{@current_user.id} AND `f`.status = 2 UNION ALL
         SELECT `w`.id, `w`.is_income, `w`.task_id, `w`.task_type, `w`.created_at, `w`.amount FROM `core_withdraw_orders` AS `w` WHERE `w`.requested_by = #{@current_user.id} AND `w`.status = 3;")
         .paginate(page: params[:page] || 1, per_page: params[:per] || 10)
      # @rmb_detail = @rmb_detail.includes(:owhat_product) if @rmb_detail.present?
    end
    sql1 = "SELECT `o`.task_id, `o`.user_id AS user_id, `o`.task_type, `o`.obi, `o`.from, `o`.is_income, `o`.created_at FROM `core_task_awards` AS `o` WHERE `o`.user_id = #{@current_user.id} AND `o`.active = 1 AND `o`.obi > 0"
    sql2 = "SELECT `f`.resource_id, `f`.user_id AS user_id, `f`.resource_type, `f`.amount, `f`.action, `f`.is_income, `f`.created_at FROM `core_expens` AS `f`  WHERE `f`.user_id = #{@current_user.id} "
    @obi_detail = Core::TaskAward.find_by_sql("(#{sql1}) UNION ALL (#{sql2}) ORDER BY created_at DESC;").paginate(page: params[:page] || 1, per_page: params[:per] || 10)
    @obi_account = @current_user.obi
    @balance_account = @current_user.verified ? @current_user.balance_account : 0
  end

  def manage

  end
end
