class Shop::Cart < ActiveRecord::Base
  include Redis::Objects

  belongs_to :user, class_name: "Core::User", foreign_key: :uid

  hash_key :my_carts

  def self.delete_cart(current_user, owner_id, order)
    # * 购物车删除
    cart = current_user.cart.my_carts
    cart_hash = current_user.cart.my_carts.all

    if cart_hash.has_key?("#{owner_id}")
      products_hash = eval(cart_hash["#{owner_id}"])
      if products_hash.has_key?("#{order[:ticket_type_id]}")
        quantity = products_hash["#{order[:ticket_type_id]}"]["quantity"].to_i - order[:quantity].to_i
        if quantity == 0 || quantity < 0
          products_hash.delete("#{order[:ticket_type_id]}")
          if products_hash.size == 0
            cart.delete("#{owner_id}")
          else
            cart["#{owner_id}"] = products_hash
            cart_hash.update("#{owner_id}" => cart["#{owner_id}"])
          end
        else
          cart["#{owner_id}"] = products_hash.update({"#{order[:ticket_type_id]}" => products_hash["#{order[:ticket_type_id]}"].update({"quantity" => quantity }) })
          cart_hash.update("#{owner_id}" => cart["#{owner_id}"])
        end
      end
    end
  end

  def self.delete_cart_by_ticket_type_id(current_user, ticket_type_id)
    # * 购物车删除
    cart = current_user.cart.my_carts
    cart_hash = current_user.cart.my_carts.all

    cart_hash.each do |k, v|
      products_hash = eval(v)
      next unless products_hash.has_key?("#{ticket_type_id}")
      if products_hash.has_key?("#{ticket_type_id}")
        products_hash.delete("#{ticket_type_id}")
        if products_hash.size == 0
          cart.delete("#{k}")
        else
          cart["#{k}"] = products_hash
          cart_hash.update("#{k}" => cart["#{k}"])
        end
      end
    end

  end

  def self.add_cart(current_user, ticket_type, task, options={})
    cart = current_user.cart.my_carts
    cart_hash = cart.all
    params = options[:params]
    ext_infos = options[:ext_infos]
    split_memo = options[:split_memo]

    if cart_hash.has_key?("#{task.user_id}")
      # 购物车中有该商家的商品
      products_hash = eval(cart_hash["#{task.user_id}"])

      if products_hash.has_key?("#{params[:ticket_type_id]}")
        # 购物车中有同样的商品
        quantity = products_hash["#{params[:ticket_type_id]}"]["quantity"].to_i + params[:quantity].to_i
        # 更新购物车
        cart["#{task.user_id}"] = products_hash.update({"#{params[:ticket_type_id]}" => products_hash["#{params[:ticket_type_id]}"].update({"quantity" => quantity, "infos" => ext_infos, "split_memo" => split_memo, "total_fee" => ticket_type.fee.to_f.round(2) * quantity.to_i }) })
      else
        # 购物车中有该商家但是没有该商品直接添加
        cart["#{task.user_id}"] = products_hash.merge!({ "#{params[:ticket_type_id]}" => { "each_limit" => ticket_type.is_each_limit ? ticket_type.each_limit : 99999999, "shop_id" => task.id, "shop_category" => task.shop_category, "cover1" => "#{task.cover_pic}?imageMogr2/auto-orient/thumbnail/!120x120r/gravity/Center/crop/120x120", "title" => task.title, "start_at" => task.start_at && task.start_at.to_s(:db), "end_at" => task.end_at && task.end_at.to_s(:db), "sale_start_at" => task.sale_start_at.to_s(:db), "sale_end_at" => task.sale_end_at.to_s(:db), "address" => task.address, "category" => ticket_type.category, "fee" => ticket_type.fee.to_f.round(2), "quantity" => params["quantity"], "total_fee" => ticket_type.fee.to_f.round(2) * params["quantity"].to_i, "infos" => ext_infos, "split_memo" => split_memo } })
      end
    else
      cart["#{task.user_id}"] = { "#{params[:ticket_type_id]}" => { "each_limit" => ticket_type.is_each_limit ? ticket_type.each_limit : 99999999, "shop_id" => task.id, "shop_category" => task.shop_category, "cover1" => "#{task.cover_pic}?imageMogr2/auto-orient/thumbnail/!120x120r/gravity/Center/crop/120x120", "title" => task.title, "start_at" => task.start_at && task.start_at.to_s(:db), "end_at" => task.end_at && task.end_at.to_s(:db), "sale_start_at" => task.sale_start_at.to_s(:db), "sale_end_at" => task.sale_end_at.to_s(:db), "address" => task.address, "category" => ticket_type.category, "fee" => ticket_type.fee.to_f.round(2), "quantity" => params["quantity"], "total_fee" => ticket_type.fee.to_f.round(2) * params["quantity"].to_i, "infos" => ext_infos, "split_memo" => split_memo } }
    end
    return cart_hash
  end

end
