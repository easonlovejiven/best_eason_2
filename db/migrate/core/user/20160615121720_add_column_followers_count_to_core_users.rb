class AddColumnFollowersCountToCoreUsers < ActiveRecord::Migration
  def change
    add_column :core_users, :followers_user_count, :integer, default: 0
    # update "UPDATE core_users SET followers_user_count = (SELECT COUNT(*) FROM `core_follows` WHERE `core_follows`.`followable_id` = `core_users`.`id` AND `core_follows`.`followable_type` = 'Core::User' AND `core_follows`.`blocked` = 0)"
    add_column :core_users, :follow_user_count, :integer, default: 0
    # update "UPDATE core_users SET follow_user_count = (SELECT COUNT(*) FROM `core_follows` WHERE `core_follows`.`blocked` = 0 AND `core_follows`.`follower_id` = `core_users`.`id` AND `core_follows`.`follower_type` = 'Core::User')"
    add_column :core_stars, :followers_user_count, :integer, default: 0
    # update "UPDATE core_stars SET followers_user_count = (SELECT COUNT(*) FROM `core_follows` WHERE `core_follows`.`followable_id` = `core_stars`.`id` AND `core_follows`.`followable_type` = 'Core::Star' AND `core_follows`.`blocked` = 0)"
  end
end
