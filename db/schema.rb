# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161104092408) do

  create_table "areas", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ancestry",   limit: 255
  end

  add_index "areas", ["ancestry"], name: "index_areas_on_ancestry", using: :btree

  create_table "core_accounts", force: :cascade do |t|
    t.string   "email",                     limit: 255
    t.string   "phone",                     limit: 255
    t.string   "crypted_password",          limit: 255
    t.string   "salt",                      limit: 255
    t.string   "remember_token",            limit: 255
    t.string   "remember_token_expires_at", limit: 255
    t.string   "source",                    limit: 255
    t.datetime "destroyed_at"
    t.string   "ip_address",                limit: 255
    t.string   "client",                    limit: 255
    t.string   "last_login_on",             limit: 255
    t.boolean  "active",                                default: true, null: false
    t.integer  "lock_version",              limit: 4,   default: 0,    null: false
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.string   "token",                     limit: 255
    t.string   "activation_code",           limit: 255
    t.datetime "activated_at"
    t.string   "login_salt",                limit: 255
  end

  add_index "core_accounts", ["email", "active"], name: "by_email_and_active", using: :btree
  add_index "core_accounts", ["phone", "active"], name: "by_phone_and_active", using: :btree

  create_table "core_addresses", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "mobile",      limit: 255
    t.string   "phone",       limit: 255
    t.string   "zip_code",    limit: 255
    t.integer  "province_id", limit: 4
    t.integer  "city_id",     limit: 4
    t.integer  "district_id", limit: 4
    t.string   "address",     limit: 255
    t.string   "addressee",   limit: 255
    t.boolean  "active",                  default: true
    t.boolean  "is_default",              default: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "core_ads", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.string   "link",         limit: 255
    t.string   "pic",          limit: 255
    t.string   "genre",        limit: 255
    t.integer  "duration",     limit: 4,   default: 3,     null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.boolean  "published",                default: false, null: false
    t.boolean  "active",                   default: true,  null: false
    t.integer  "lock_version", limit: 4,   default: 0,     null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "core_ads", ["active", "published", "start_at", "end_at"], name: "by_start_at_and_end_at", using: :btree

  create_table "core_areas", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "ancestry",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "core_banners", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.string   "link",         limit: 255
    t.string   "pic",          limit: 255
    t.string   "genre",        limit: 255
    t.string   "position",     limit: 255
    t.text     "description",  limit: 65535
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.boolean  "published",                  default: false, null: false
    t.boolean  "active",                     default: true,  null: false
    t.integer  "lock_version", limit: 4,     default: 0,     null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "template",     limit: 255
    t.string   "template_id",  limit: 255
    t.string   "pic2",         limit: 255
    t.integer  "sequence",     limit: 4,     default: 9999,  null: false
  end

  add_index "core_banners", ["active", "published", "start_at", "end_at"], name: "by_start_at_and_end_at_banners", using: :btree

  create_table "core_connections", force: :cascade do |t|
    t.integer  "account_id",     limit: 4
    t.string   "site",           limit: 255,                  null: false
    t.text     "token",          limit: 65535
    t.text     "secret",         limit: 65535
    t.text     "refresh_token",  limit: 65535
    t.datetime "expired_at"
    t.text     "data",           limit: 65535
    t.string   "identifier",     limit: 255
    t.string   "email",          limit: 255
    t.string   "name",           limit: 255
    t.string   "sex",            limit: 255
    t.string   "pic",            limit: 255
    t.string   "phone",          limit: 255
    t.boolean  "active",                       default: true, null: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "owhat2_id",      limit: 4
    t.string   "old_identifier", limit: 255
  end

  add_index "core_connections", ["account_id", "site"], name: "by_account_id_and_site", using: :btree
  add_index "core_connections", ["active", "account_id"], name: "by_active_and_account_id", using: :btree
  add_index "core_connections", ["active", "site", "identifier"], name: "by_active_and_site_and_identifier", using: :btree

  create_table "core_expens", force: :cascade do |t|
    t.integer  "user_id",             limit: 4
    t.integer  "resource_id",         limit: 4
    t.string   "resource_type",       limit: 255
    t.decimal  "amount",                            precision: 8, scale: 2, default: 0.0
    t.string   "action",              limit: 255
    t.string   "currency",            limit: 255
    t.string   "status",              limit: 255
    t.integer  "lock_version",        limit: 4,                             default: 0,     null: false
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
    t.integer  "task_id",             limit: 4
    t.boolean  "is_income",                                                 default: false
    t.integer  "shop_ticket_type_id", limit: 4
    t.integer  "quantity",            limit: 4
    t.boolean  "active",                                                    default: true
    t.string   "order_no",            limit: 255
    t.text     "address",             limit: 65535
    t.integer  "address_id",          limit: 4
    t.string   "phone",               limit: 255
    t.string   "user_name",           limit: 255
  end

  add_index "core_expens", ["order_no"], name: "by_order_no", using: :btree
  add_index "core_expens", ["user_id"], name: "by_user_id", using: :btree

  create_table "core_exported_orders", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.boolean  "active",                    default: true
    t.integer  "task_id",       limit: 4
    t.string   "task_type",     limit: 255
    t.string   "file_name",     limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "user_type",     limit: 255
    t.datetime "paid_start_at"
    t.datetime "paid_end_at"
    t.boolean  "exclude_free",              default: false
    t.string   "order_class",   limit: 255
  end

  create_table "core_feedbacks", force: :cascade do |t|
    t.string   "user_id",    limit: 255
    t.text     "content",    limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "core_findings", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.string   "url",          limit: 255
    t.string   "pic",          limit: 255
    t.text     "description",  limit: 65535
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.boolean  "published",                  default: false, null: false
    t.boolean  "active",                     default: true,  null: false
    t.integer  "lock_version", limit: 4,     default: 0,     null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "category",     limit: 255
    t.integer  "count",        limit: 4,     default: 0
    t.string   "pic2",         limit: 255
  end

  create_table "core_follows", force: :cascade do |t|
    t.integer  "followable_id",   limit: 4,                   null: false
    t.string   "followable_type", limit: 255,                 null: false
    t.integer  "follower_id",     limit: 4,                   null: false
    t.string   "follower_type",   limit: 255,                 null: false
    t.boolean  "blocked",                     default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "core_follows", ["followable_id", "followable_type"], name: "fk_followables", using: :btree
  add_index "core_follows", ["follower_id", "follower_type"], name: "fk_follows", using: :btree

  create_table "core_hot_records", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "synonym",    limit: 255
    t.integer  "position",   limit: 4
    t.integer  "creator_id", limit: 4
    t.integer  "updater_id", limit: 4
    t.boolean  "active",                 default: true
    t.boolean  "published",              default: true
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "core_identities", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "name",        limit: 255
    t.string   "org_name",    limit: 255
    t.string   "org_pic",     limit: 255
    t.string   "id_pic",      limit: 255
    t.string   "related_ids", limit: 255
    t.text     "description", limit: 65535
    t.boolean  "is_org",                    default: false, null: false
    t.integer  "status",      limit: 4,     default: 0
    t.boolean  "active",                    default: true,  null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "id_pic2",     limit: 255
    t.integer  "updater_id",  limit: 4
    t.integer  "creator_id",  limit: 4
    t.string   "phone",       limit: 255
    t.string   "position",    limit: 255
  end

  create_table "core_images", force: :cascade do |t|
    t.string   "pic",          limit: 255
    t.string   "key",          limit: 255
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.boolean  "published",                default: false, null: false
    t.boolean  "active",                   default: true,  null: false
    t.integer  "lock_version", limit: 4,   default: 0,     null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "core_keywords", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.boolean  "active",                   default: true, null: false
    t.datetime "destroyed_at"
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "core_keywords", ["active", "name"], name: "by_active_and_name", using: :btree

  create_table "core_logins", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.date     "login_on"
    t.string   "ip_address",     limit: 20
    t.string   "client",         limit: 255
    t.string   "device_id",      limit: 255
    t.string   "device_models",  limit: 255
    t.string   "manufacturer",   limit: 255
    t.string   "system_version", limit: 255
    t.text     "user_agent",     limit: 65535
    t.datetime "created_at"
  end

  add_index "core_logins", ["user_id", "login_on"], name: "index_core_logins_on_user_id_and_login_on", using: :btree

  create_table "core_mobile_codes", force: :cascade do |t|
    t.string   "mobile",     limit: 255
    t.string   "code",       limit: 255
    t.integer  "end_time",   limit: 4
    t.string   "kind",       limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "client",     limit: 255, default: "mobile"
    t.boolean  "verified",               default: false
  end

  add_index "core_mobile_codes", ["mobile"], name: "by_mobile", using: :btree

  create_table "core_punches", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.boolean  "active",                 default: true, null: false
    t.integer  "lock_version", limit: 4, default: 0,    null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "star_id",      limit: 4
  end

  create_table "core_recordings", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.integer  "user_id",      limit: 4
    t.string   "genre",        limit: 255
    t.integer  "count",        limit: 4,   default: 1,    null: false
    t.boolean  "active",                   default: true, null: false
    t.integer  "lock_version", limit: 4,   default: 0,    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "core_recordings", ["active", "name", "genre"], name: "by_name_and_genre", using: :btree

  create_table "core_signs", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "time",       limit: 4
    t.date     "sign_at"
    t.boolean  "active"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "core_smss", force: :cascade do |t|
    t.integer  "editor_id",    limit: 4
    t.integer  "trade_id",     limit: 4
    t.integer  "costumer_id",  limit: 4
    t.string   "phone",        limit: 255
    t.text     "content",      limit: 65535
    t.text     "remark",       limit: 65535
    t.boolean  "success",                    default: false, null: false
    t.boolean  "active",                     default: true,  null: false
    t.integer  "lock_version", limit: 4,     default: 0,     null: false
    t.datetime "send_at"
    t.integer  "user_id",      limit: 4
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  create_table "core_stars", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.string   "pic",                  limit: 255
    t.text     "description",          limit: 65535
    t.string   "company",              limit: 255
    t.text     "works",                limit: 65535
    t.text     "acting",               limit: 65535
    t.text     "related_ids",          limit: 65535
    t.integer  "creator_id",           limit: 4
    t.integer  "updater_id",           limit: 4
    t.integer  "position",             limit: 4,     default: 0,     null: false
    t.boolean  "published",                          default: false, null: false
    t.boolean  "active",                             default: true,  null: false
    t.integer  "lock_version",         limit: 4,     default: 0,     null: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "sign",                 limit: 255
    t.string   "nickname",             limit: 255
    t.string   "cover",                limit: 255
    t.integer  "participants",         limit: 4,     default: 0
    t.integer  "org_id",               limit: 4
    t.integer  "fans_count",           limit: 4,     default: 0
    t.integer  "category",             limit: 4,     default: 0
    t.integer  "followers_user_count", limit: 4,     default: 0
  end

  add_index "core_stars", ["active", "name"], name: "by_active_name", using: :btree
  add_index "core_stars", ["active", "published", "participants", "created_at"], name: "index_core_stars_on_participants_and_active", using: :btree

  create_table "core_task_awards", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "task_id",         limit: 4
    t.string   "task_type",       limit: 255
    t.integer  "empirical_value", limit: 4,   default: 0
    t.integer  "obi",             limit: 4,   default: 0
    t.boolean  "active",                      default: true
    t.string   "from",            limit: 255
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "is_income",                   default: true
  end

  create_table "core_users", force: :cascade do |t|
    t.text     "pic",                  limit: 65535
    t.string   "name",                 limit: 255
    t.string   "sex",                  limit: 255
    t.string   "birthday",             limit: 255
    t.integer  "level",                limit: 4,     default: 0
    t.boolean  "active",                             default: true,  null: false
    t.integer  "lock_version",         limit: 4,     default: 0,     null: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "role",                 limit: 255
    t.integer  "identity",             limit: 4,     default: 0
    t.integer  "position",             limit: 4,     default: 0
    t.datetime "verified_at"
    t.boolean  "verified",                           default: false
    t.integer  "creator_id",           limit: 4
    t.integer  "updater_id",           limit: 4
    t.integer  "empirical_value",      limit: 4,     default: 0
    t.integer  "obi",                  limit: 4,     default: 0
    t.text     "signature",            limit: 65535
    t.integer  "participants",         limit: 4,     default: 0
    t.integer  "image_id",             limit: 4
    t.boolean  "privacy",                            default: true
    t.integer  "old_uid",              limit: 4
    t.integer  "followers_user_count", limit: 4,     default: 0
    t.integer  "follow_user_count",    limit: 4,     default: 0
    t.boolean  "is_auto_share"
  end

  add_index "core_users", ["active", "id"], name: "by_active_and_id", using: :btree
  add_index "core_users", ["active", "identity"], name: "by_active_and_identity", using: :btree
  add_index "core_users", ["active", "participants", "created_at"], name: "index_core_users_on_participants_and_active", using: :btree
  add_index "core_users", ["created_at"], name: "by_created_at", using: :btree
  add_index "core_users", ["identity", "participants", "position", "active"], name: "by_identity_actibe", using: :btree
  add_index "core_users", ["name", "active"], name: "by_name_and_active", using: :btree
  add_index "core_users", ["old_uid", "active"], name: "by_old_uid_actibe", using: :btree
  add_index "core_users", ["verified", "active"], name: "by_verified_and_active", using: :btree

  create_table "core_withdraw_orders", force: :cascade do |t|
    t.decimal  "amount",                               precision: 8, scale: 2, default: 0.0
    t.integer  "tickets_count",          limit: 4
    t.string   "receiver_name",          limit: 255
    t.string   "receiver_account",       limit: 255
    t.string   "bank_name",              limit: 255
    t.text     "requestor_remark",       limit: 65535
    t.integer  "requested_by",           limit: 4
    t.date     "requested_at"
    t.string   "verifier_remark",        limit: 255
    t.date     "verified_at"
    t.integer  "verified_by",            limit: 4
    t.datetime "cut_off_at"
    t.string   "mobile",                 limit: 255
    t.string   "email",                  limit: 255
    t.integer  "status",                 limit: 4,                             default: 1
    t.boolean  "active",                                                       default: true
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.integer  "task_id",                limit: 4
    t.string   "task_type",              limit: 255
    t.boolean  "is_income",                                                    default: false
    t.integer  "core_exported_order_id", limit: 4
  end

  add_index "core_withdraw_orders", ["status", "requested_by"], name: "by_withdraw_status_and_requested_by", using: :btree
  add_index "core_withdraw_orders", ["task_id", "task_type", "requested_by", "requested_at", "status"], name: "task_and_request", unique: true, using: :btree

  create_table "manage_accounts", force: :cascade do |t|
    t.string   "email",                     limit: 255
    t.string   "phone",                     limit: 255
    t.string   "crypted_password",          limit: 255
    t.string   "salt",                      limit: 255
    t.string   "remember_token",            limit: 255
    t.string   "remember_token_expires_at", limit: 255
    t.string   "source",                    limit: 255
    t.datetime "destroyed_at"
    t.string   "ip_address",                limit: 255
    t.string   "client",                    limit: 255
    t.string   "last_login_on",             limit: 255
    t.boolean  "active",                                default: true, null: false
    t.integer  "lock_version",              limit: 4,   default: 0,    null: false
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
  end

  create_table "manage_editors", force: :cascade do |t|
    t.integer  "creator_id",    limit: 4
    t.string   "name",          limit: 255
    t.integer  "role_id",       limit: 4
    t.integer  "company_id",    limit: 4
    t.datetime "destroyed_at"
    t.integer  "updater_id",    limit: 4
    t.integer  "department_id", limit: 4
    t.integer  "supervisor_id", limit: 4
    t.string   "position",      limit: 255
    t.string   "prefix",        limit: 255
    t.boolean  "active",                    default: true, null: false
    t.integer  "lock_version",  limit: 4,   default: 0,    null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "manage_grants", force: :cascade do |t|
    t.integer  "editor_id",    limit: 4
    t.integer  "role_id",      limit: 4
    t.integer  "updater_id",   limit: 4
    t.integer  "creator_id",   limit: 4
    t.boolean  "active",                 default: true, null: false
    t.integer  "lock_version", limit: 4, default: 0,    null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "manage_grants", ["active", "editor_id", "role_id"], name: "by_active_and_editor_id_and_role_id", using: :btree

  create_table "manage_roles", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.text     "description",           limit: 65535
    t.integer  "creator_id",            limit: 4
    t.integer  "updater_id",            limit: 4
    t.datetime "destroyed_at"
    t.boolean  "active",                              default: true, null: false
    t.integer  "lock_version",          limit: 4,     default: 0,    null: false
    t.integer  "manage_grant",          limit: 4,     default: 0
    t.integer  "manage_editor",         limit: 4,     default: 0
    t.integer  "manage_role",           limit: 4,     default: 0
    t.integer  "core_account",          limit: 4,     default: 0
    t.integer  "core_user",             limit: 4,     default: 0
    t.integer  "core_keyword",          limit: 4,     default: 0
    t.integer  "core_sms",              limit: 4,     default: 0
    t.integer  "shop_address",          limit: 4,     default: 0
    t.integer  "shop_funding",          limit: 4,     default: 0
    t.integer  "shop_order",            limit: 4,     default: 0
    t.integer  "shop_order_item",       limit: 4,     default: 0
    t.integer  "shop_price_category",   limit: 4,     default: 0
    t.integer  "shop_product",          limit: 4,     default: 0
    t.integer  "shop_ticket_type",      limit: 4,     default: 0
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "shop_topic",            limit: 4,     default: 0
    t.integer  "shop_event",            limit: 4,     default: 0
    t.integer  "core_star",             limit: 4,     default: 0
    t.integer  "core_recording",        limit: 4,     default: 0
    t.integer  "core_ad",               limit: 4,     default: 0
    t.integer  "shop_topic_dynamic",    limit: 4,     default: 0
    t.integer  "core_banner",           limit: 4,     default: 0
    t.integer  "shop_freight_template", limit: 4,     default: 0
    t.integer  "shop_subject",          limit: 4,     default: 0
    t.integer  "welfare_paper",         limit: 4,     default: 0
    t.integer  "welfare_letter",        limit: 4,     default: 0
    t.integer  "core_finding",          limit: 4,     default: 0
    t.integer  "shop_task",             limit: 4,     default: 0
    t.integer  "core_image",            limit: 4,     default: 0
    t.integer  "shop_task_image",       limit: 4,     default: 0
    t.integer  "notification_send",     limit: 4,     default: 0
    t.integer  "core_withdraw_order",   limit: 4,     default: 0
    t.integer  "shop_funding_order",    limit: 4,     default: 0
    t.integer  "core_exported_order",   limit: 4,     default: 0
    t.integer  "qa_poster",             limit: 4,     default: 0
    t.integer  "core_hot_record",       limit: 4,     default: 0
    t.integer  "welfare_event",         limit: 4,     default: 0
    t.integer  "welfare_product",       limit: 4,     default: 0
    t.integer  "core_expen",            limit: 4,     default: 0
    t.integer  "core_identity",         limit: 4,     default: 0
    t.integer  "shop_media",            limit: 4,     default: 0
    t.integer  "statistic",             limit: 4,     default: 0
  end

  create_table "manage_users", force: :cascade do |t|
    t.string   "pic",          limit: 255
    t.string   "name",         limit: 255
    t.string   "sex",          limit: 255
    t.string   "birthday",     limit: 255
    t.string   "level",        limit: 255
    t.boolean  "active",                   default: true, null: false
    t.integer  "lock_version", limit: 4,   default: 0,    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.datetime "login_at"
  end

  create_table "notification_send_statistics", force: :cascade do |t|
    t.integer  "send_id",    limit: 4
    t.integer  "uid",        limit: 4
    t.string   "platform",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "notification_send_statistics", ["send_id", "platform"], name: "by_send_id_and_platform", using: :btree

  create_table "notification_sends", force: :cascade do |t|
    t.text     "content",      limit: 65535
    t.integer  "sendor_id",    limit: 4
    t.string   "push_content", limit: 255
    t.integer  "receivor_id",  limit: 4
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.boolean  "status",                     default: false
    t.boolean  "active",                     default: true
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.string   "extr",         limit: 255
    t.string   "skip_channel", limit: 255
    t.integer  "skip_id",      limit: 4
    t.integer  "send_status",  limit: 4,     default: 1
    t.datetime "send_date"
    t.integer  "send_type",    limit: 4,     default: 1
    t.integer  "push_type",    limit: 4,     default: 1
    t.string   "object_name",  limit: 255,   default: "custom"
    t.string   "os",           limit: 255,   default: "all"
  end

  add_index "notification_sends", ["send_date", "send_status"], name: "index_notification_sends_on_send_date_and_send_status", using: :btree

  create_table "qa_answers", force: :cascade do |t|
    t.integer  "question_id",  limit: 4
    t.text     "content",      limit: 65535
    t.boolean  "right",                      default: false, null: false
    t.boolean  "active",                     default: true,  null: false
    t.integer  "lock_version", limit: 4,     default: 0,     null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  create_table "qa_posters", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.string   "pic",          limit: 255
    t.integer  "user_id",      limit: 4
    t.boolean  "active",                   default: true,  null: false
    t.integer  "lock_version", limit: 4,   default: 0,     null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "star_list",    limit: 255
    t.string   "guide",        limit: 255
    t.boolean  "is_share",                 default: false
  end

  create_table "qa_questions", force: :cascade do |t|
    t.integer  "poster_id",    limit: 4
    t.text     "title",        limit: 65535
    t.string   "pic",          limit: 255
    t.boolean  "active",                     default: true, null: false
    t.integer  "lock_version", limit: 4,     default: 0,    null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "answer_id",    limit: 4
  end

  create_table "send_statistics", force: :cascade do |t|
    t.integer  "send_id",    limit: 4
    t.string   "platform",   limit: 255
    t.date     "click_date"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "shop_addresses", force: :cascade do |t|
    t.string   "mobile",       limit: 255
    t.integer  "user_id",      limit: 4
    t.string   "zip_code",     limit: 255
    t.integer  "province_id",  limit: 4
    t.integer  "city_id",      limit: 4
    t.integer  "district_id",  limit: 4
    t.string   "address",      limit: 255
    t.string   "receive_name", limit: 255
    t.boolean  "is_default"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "active",                   default: true
  end

  create_table "shop_carts", force: :cascade do |t|
    t.integer  "uid",        limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "shop_carts", ["uid"], name: "by_uid", using: :btree

  create_table "shop_comments", force: :cascade do |t|
    t.integer  "parent_id",  limit: 4,     default: 0
    t.integer  "task_id",    limit: 4
    t.string   "task_type",  limit: 255
    t.text     "content",    limit: 65535
    t.integer  "user_id",    limit: 4
    t.boolean  "active",                   default: true
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "shop_dynamic_comments", force: :cascade do |t|
    t.string   "content",    limit: 255
    t.integer  "user_id",    limit: 4
    t.integer  "parent_id",  limit: 4,   default: 0
    t.integer  "dynamic_id", limit: 4
    t.boolean  "active",                 default: true
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "seed_count", limit: 4,   default: 0
  end

  create_table "shop_dynamic_likes", force: :cascade do |t|
    t.integer  "user_id",               limit: 4
    t.integer  "shop_topic_dynamic_id", limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "shop_events", force: :cascade do |t|
    t.integer  "user_id",             limit: 4
    t.string   "title",               limit: 255
    t.integer  "area_id",             limit: 4
    t.string   "address",             limit: 255
    t.integer  "ticket_limit",        limit: 4
    t.integer  "ticket_total",        limit: 4
    t.string   "mobile",              limit: 255
    t.text     "description",         limit: 65535
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "seckill_start_at"
    t.float    "fee",                 limit: 24
    t.float    "original_fee",        limit: 24
    t.boolean  "is_hot"
    t.float    "latitude",            limit: 24
    t.float    "longitude",           limit: 24
    t.integer  "comments_count",      limit: 4,                    default: 0
    t.integer  "tickets_count",       limit: 4,                    default: 0
    t.boolean  "free",                                             default: false
    t.boolean  "sync_weibo"
    t.boolean  "sync_qq"
    t.string   "star_list",           limit: 255
    t.string   "ext_info",            limit: 255
    t.string   "video_url",           limit: 255
    t.string   "descripe_key",        limit: 255
    t.string   "cover1",              limit: 255
    t.string   "cover2",              limit: 255
    t.string   "cover3",              limit: 255
    t.string   "key1",                limit: 255
    t.string   "key2",                limit: 255
    t.string   "key3",                limit: 255
    t.integer  "priority",            limit: 4,                    default: 100
    t.datetime "deleted_at"
    t.datetime "sale_start_at"
    t.datetime "sale_end_at"
    t.datetime "select_at"
    t.text     "descripe2",           limit: 65535
    t.boolean  "hidden",                                           default: false
    t.string   "descripe_cover",      limit: 255
    t.boolean  "send_coupon_code",                                 default: false
    t.integer  "flag_id",             limit: 4
    t.string   "cached_tag_list",     limit: 255
    t.string   "product_type",        limit: 255,                  default: "event"
    t.decimal  "funding_target",                    precision: 10
    t.string   "live_room_id",        limit: 255
    t.boolean  "is_need_express",                                  default: false
    t.boolean  "send_sms",                                         default: true
    t.integer  "parent_id",           limit: 4
    t.integer  "lft",                 limit: 4
    t.integer  "rgt",                 limit: 4
    t.integer  "trade_expired_time",  limit: 4,                    default: 20
    t.boolean  "is_share",                                         default: true
    t.string   "cached_star_list",    limit: 255
    t.integer  "creator_id",          limit: 4
    t.datetime "created_at",                                                         null: false
    t.datetime "updated_at",                                                         null: false
    t.boolean  "active",                                           default: true
    t.integer  "page_sort",           limit: 4
    t.integer  "freight_template_id", limit: 4
    t.boolean  "need_freight",                                     default: false
    t.string   "shop_category",       limit: 255
    t.string   "guide",               limit: 255
    t.integer  "updater_id",          limit: 4
    t.boolean  "is_rush",                                          default: false
  end

  add_index "shop_events", ["active", "title", "user_id", "mobile", "star_list"], name: "event_active", unique: true, using: :btree

  create_table "shop_ext_info_values", force: :cascade do |t|
    t.integer  "ext_info_id",   limit: 4
    t.integer  "resource_id",   limit: 4
    t.string   "value",         limit: 255
    t.boolean  "active",                    default: true
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "resource_type", limit: 255
  end

  create_table "shop_ext_infos", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.integer  "task_id",    limit: 4
    t.datetime "deleted_at"
    t.boolean  "require"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "task_type",  limit: 255
  end

  create_table "shop_freight_templates", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.boolean  "active",                     default: true
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "user_id",        limit: 4
    t.string   "start_position", limit: 255
    t.string   "user_type",      limit: 255
  end

  create_table "shop_freights", force: :cascade do |t|
    t.integer  "freight_template_id", limit: 4
    t.string   "destination",         limit: 255
    t.boolean  "active",                                                  default: true
    t.integer  "frist_item",          limit: 4,                           default: 1
    t.integer  "reforwarding_item",   limit: 4,                           default: 1
    t.decimal  "first_fee",                       precision: 8, scale: 2, default: 0.0
    t.decimal  "reforwarding_fee",                precision: 8, scale: 2, default: 0.0
    t.boolean  "id_delivery",                                             default: false
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
    t.string   "start_position",      limit: 255
  end

  create_table "shop_funding_orders", force: :cascade do |t|
    t.string   "order_no",            limit: 255
    t.integer  "shop_funding_id",     limit: 4
    t.integer  "user_id",             limit: 4
    t.integer  "status",              limit: 4,                             default: 1
    t.integer  "pay_type",            limit: 4,                             default: 1
    t.integer  "quantity",            limit: 4,                             default: 1
    t.decimal  "payment",                           precision: 8, scale: 2, default: 0.0
    t.datetime "paid_at"
    t.datetime "pay_at"
    t.datetime "canceled_at"
    t.datetime "checked_at"
    t.integer  "address_id",          limit: 4
    t.integer  "owner_id",            limit: 4
    t.integer  "shop_ticket_type_id", limit: 4
    t.boolean  "active",                                                    default: true
    t.datetime "created_at",                                                                          null: false
    t.datetime "updated_at",                                                                          null: false
    t.string   "platform",            limit: 255
    t.string   "memo",                limit: 255
    t.string   "user_name",           limit: 255
    t.string   "phone",               limit: 255
    t.string   "shop_funding_type",   limit: 255,                           default: "Shop::Funding"
    t.boolean  "is_income",                                                 default: true
    t.string   "address",             limit: 255
    t.string   "split_memo",          limit: 255
    t.text     "question_memo",       limit: 65535
    t.integer  "creator_id",          limit: 4
    t.integer  "updater_id",          limit: 4
    t.datetime "updated_paid_at"
  end

  add_index "shop_funding_orders", ["shop_funding_id"], name: "by_shop_funding_id", using: :btree
  add_index "shop_funding_orders", ["status", "owner_id"], name: "by_funding_status_and_owner_id", using: :btree

  create_table "shop_funding_progresses", force: :cascade do |t|
    t.text     "describe",        limit: 65535
    t.boolean  "active",                        default: true
    t.integer  "shop_funding_id", limit: 4
    t.integer  "user_id",         limit: 4
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_index "shop_funding_progresses", ["active", "shop_funding_id"], name: "by_shop_progress_funding_id", using: :btree
  add_index "shop_funding_progresses", ["active", "user_id"], name: "by_shop_progress_user_id", using: :btree

  create_table "shop_funding_users", force: :cascade do |t|
    t.integer  "shop_funding_id", limit: 4
    t.integer  "core_user_id",    limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "shop_fundings", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.boolean  "active",                                       default: true
    t.integer  "user_id",         limit: 4
    t.text     "description",     limit: 65535
    t.string   "cover1",          limit: 255
    t.string   "cover2",          limit: 255
    t.string   "cover3",          limit: 255
    t.string   "video_url",       limit: 255
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "sale_start_at"
    t.datetime "sale_end_at"
    t.string   "address",         limit: 255
    t.string   "mobile",          limit: 255
    t.boolean  "free",                                         default: false
    t.decimal  "funding_target",                precision: 10
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.integer  "page_sort",       limit: 4
    t.string   "descripe_cover",  limit: 255
    t.text     "descripe2",       limit: 65535
    t.string   "star_list",       limit: 255
    t.boolean  "is_share",                                     default: true
    t.integer  "creator_id",      limit: 4
    t.string   "key1",            limit: 255
    t.string   "key2",            limit: 255
    t.string   "key3",            limit: 255
    t.string   "descripe_key",    limit: 255
    t.string   "shop_category",   limit: 255
    t.string   "guide",           limit: 255
    t.integer  "updater_id",      limit: 4
    t.text     "result_describe", limit: 65535
    t.boolean  "need_address",                                 default: false
  end

  add_index "shop_fundings", ["active", "title", "user_id", "mobile", "star_list"], name: "funding_active", unique: true, using: :btree

  create_table "shop_media", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.datetime "start_at"
    t.datetime "end_at"
    t.string   "star_list",    limit: 255
    t.string   "url",          limit: 255
    t.string   "pic",          limit: 255
    t.integer  "user_id",      limit: 4
    t.boolean  "active",                     default: true,  null: false
    t.integer  "lock_version", limit: 4,     default: 0,     null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "guide",        limit: 255
    t.boolean  "is_share",                   default: false
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.text     "description",  limit: 65535
    t.string   "kind",         limit: 255,   default: "url"
  end

  create_table "shop_order_items", force: :cascade do |t|
    t.string   "order_no",            limit: 255
    t.integer  "owhat_product_id",    limit: 4
    t.string   "owhat_product_type",  limit: 255
    t.integer  "user_id",             limit: 4
    t.string   "code",                limit: 255
    t.integer  "status",              limit: 4,                             default: 1
    t.integer  "pay_type",            limit: 4,                             default: 1
    t.integer  "quantity",            limit: 4
    t.decimal  "payment",                           precision: 8, scale: 2, default: 0.0
    t.datetime "paid_at"
    t.datetime "canceled_at"
    t.string   "qr_code",             limit: 255
    t.datetime "checked_at"
    t.string   "qr_code_fingerprint", limit: 255
    t.boolean  "is_deleted"
    t.datetime "paid_sms_sent_at"
    t.datetime "qr_code_created_at"
    t.string   "qr_path_cache",       limit: 255
    t.datetime "alipay_payment_at"
    t.integer  "address_id",          limit: 4
    t.integer  "owner_id",            limit: 4
    t.integer  "order_id",            limit: 4
    t.integer  "shop_ticket_type_id", limit: 4
    t.datetime "created_at",                                                               null: false
    t.datetime "updated_at",                                                               null: false
    t.string   "memo",                limit: 255
    t.boolean  "active",                                                    default: true
    t.string   "platform",            limit: 255
    t.string   "user_name",           limit: 255
    t.string   "phone",               limit: 255
    t.string   "address",             limit: 255
    t.decimal  "freight_fee",                       precision: 8, scale: 2, default: 0.0
    t.boolean  "is_income",                                                 default: true
    t.datetime "expired_at"
    t.string   "basic_order_no",      limit: 255
    t.string   "split_memo",          limit: 255
    t.text     "question_memo",       limit: 65535
    t.integer  "creator_id",          limit: 4
    t.integer  "updater_id",          limit: 4
    t.datetime "updated_paid_at"
  end

  add_index "shop_order_items", ["owhat_product_id", "owhat_product_type"], name: "by_owhat_product_id_and_owhat_product_type", using: :btree
  add_index "shop_order_items", ["status", "owner_id"], name: "by_shop_status_and_owner_id", using: :btree
  add_index "shop_order_items", ["status"], name: "status", using: :btree
  add_index "shop_order_items", ["status"], name: "status_2", using: :btree
  add_index "shop_order_items", ["status"], name: "status_3", using: :btree
  add_index "shop_order_items", ["status"], name: "status_4", using: :btree

  create_table "shop_orders", force: :cascade do |t|
    t.string   "order_no",        limit: 255
    t.decimal  "total_fee",                     precision: 8, scale: 2, default: 0.0
    t.integer  "status",          limit: 4,                             default: 1
    t.string   "platform",        limit: 255
    t.integer  "address_id",      limit: 4
    t.datetime "paid_at"
    t.integer  "user_id",         limit: 4
    t.boolean  "is_deleted"
    t.datetime "created_at",                                                           null: false
    t.datetime "updated_at",                                                           null: false
    t.integer  "pay_type",        limit: 4
    t.boolean  "active",                                                default: true
    t.decimal  "freight_fee",                   precision: 8, scale: 2, default: 0.0
    t.datetime "expired_at"
    t.text     "question_memo",   limit: 65535
    t.string   "phone",           limit: 255
    t.datetime "updated_paid_at"
  end

  create_table "shop_pictures", force: :cascade do |t|
    t.integer  "pictureable_id",          limit: 4
    t.string   "pictureable_type",        limit: 255
    t.string   "cover",                   limit: 255
    t.integer  "position",                limit: 4
    t.string   "key",                     limit: 255
    t.integer  "comments_count",          limit: 4
    t.integer  "cached_votes_total",      limit: 4,   default: 0
    t.integer  "cached_votes_score",      limit: 4,   default: 0
    t.integer  "cached_votes_up",         limit: 4,   default: 0
    t.integer  "cached_votes_down",       limit: 4,   default: 0
    t.integer  "cached_weighted_score",   limit: 4,   default: 0
    t.integer  "cached_weighted_total",   limit: 4,   default: 0
    t.float    "cached_weighted_average", limit: 24,  default: 0.0
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "user_id",                 limit: 4
  end

  add_index "shop_pictures", ["cached_votes_down"], name: "index_shop_pictures_on_cached_votes_down", using: :btree
  add_index "shop_pictures", ["cached_votes_score"], name: "index_shop_pictures_on_cached_votes_score", using: :btree
  add_index "shop_pictures", ["cached_votes_total"], name: "index_shop_pictures_on_cached_votes_total", using: :btree
  add_index "shop_pictures", ["cached_votes_up"], name: "index_shop_pictures_on_cached_votes_up", using: :btree
  add_index "shop_pictures", ["cached_weighted_average"], name: "index_shop_pictures_on_cached_weighted_average", using: :btree
  add_index "shop_pictures", ["cached_weighted_score"], name: "index_shop_pictures_on_cached_weighted_score", using: :btree
  add_index "shop_pictures", ["cached_weighted_total"], name: "index_shop_pictures_on_cached_weighted_total", using: :btree

  create_table "shop_price_categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.boolean  "active",                 default: true
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "user_id",    limit: 4
  end

  create_table "shop_products", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.boolean  "active",                            default: true
    t.integer  "user_id",             limit: 4
    t.text     "description",         limit: 65535
    t.string   "cover1",              limit: 255
    t.string   "cover2",              limit: 255
    t.string   "cover3",              limit: 255
    t.string   "video_url",           limit: 255
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "sale_start_at"
    t.datetime "sale_end_at"
    t.string   "address",             limit: 255
    t.string   "mobile",              limit: 255
    t.boolean  "free",                              default: false
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "page_sort",           limit: 4
    t.integer  "creator_id",          limit: 4
    t.boolean  "is_need_express",                   default: true
    t.string   "descripe_cover",      limit: 255
    t.text     "descripe2",           limit: 65535
    t.string   "key1",                limit: 255
    t.string   "key2",                limit: 255
    t.string   "key3",                limit: 255
    t.string   "descripe_key",        limit: 255
    t.string   "star_list",           limit: 255
    t.boolean  "is_share",                          default: true
    t.integer  "freight_template_id", limit: 4
    t.string   "shop_category",       limit: 255
    t.string   "guide",               limit: 255
    t.integer  "updater_id",          limit: 4
    t.boolean  "is_rush",                           default: false
    t.integer  "trade_expired_time",  limit: 4,     default: 20
  end

  add_index "shop_products", ["active", "title", "user_id", "mobile", "star_list"], name: "product_active", unique: true, using: :btree

  create_table "shop_subjects", force: :cascade do |t|
    t.string   "guide",         limit: 255
    t.text     "description",   limit: 65535
    t.integer  "user_id",       limit: 4
    t.integer  "creator_id",    limit: 4
    t.boolean  "active",                      default: true
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.string   "star_list",     limit: 11
    t.text     "title",         limit: 65535
    t.integer  "updater_id",    limit: 4
    t.string   "key",           limit: 255
    t.string   "cover1",        limit: 255
    t.integer  "status",        limit: 4,     default: 0
    t.datetime "start_at"
    t.string   "live_url",      limit: 255
    t.string   "storage_url",   limit: 255
    t.string   "shop_category", limit: 255,   default: "shop_subjects"
    t.string   "category",      limit: 255
    t.boolean  "is_share",                    default: true
  end

  create_table "shop_task_images", force: :cascade do |t|
    t.string   "pic",          limit: 255
    t.string   "key",          limit: 255
    t.string   "category",     limit: 255
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.boolean  "published",                default: false, null: false
    t.boolean  "active",                   default: true,  null: false
    t.integer  "lock_version", limit: 4,   default: 0,     null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "shop_task_stars", force: :cascade do |t|
    t.integer  "shop_task_id", limit: 4
    t.integer  "core_star_id", limit: 4
    t.boolean  "active",                 default: true
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "shop_tasks", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.text     "description",  limit: 65535
    t.boolean  "active",                     default: true
    t.integer  "user_id",      limit: 4
    t.integer  "creator_id",   limit: 4
    t.integer  "shop_id",      limit: 4
    t.string   "shop_type",    limit: 255
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "guide",        limit: 255
    t.string   "pic",          limit: 255
    t.string   "category",     limit: 255
    t.string   "star_list",    limit: 255
    t.integer  "participants", limit: 4,     default: 0
    t.integer  "position",     limit: 4,     default: 0
    t.boolean  "is_complete",                default: false
    t.datetime "completed_at"
    t.boolean  "free",                       default: false
    t.boolean  "is_top",                     default: false
    t.datetime "expired_at"
    t.string   "star_names",   limit: 255
    t.integer  "updater_id",   limit: 4
    t.boolean  "published",                  default: false
    t.datetime "created_time"
  end

  add_index "shop_tasks", ["active", "category", "shop_type"], name: "by_category_and_shop_type", using: :btree
  add_index "shop_tasks", ["active", "is_top", "participants", "position"], name: "by_is_top_and_position", using: :btree
  add_index "shop_tasks", ["active", "participants", "position"], name: "by_active_and_participants", using: :btree
  add_index "shop_tasks", ["active", "published", "category"], name: "by_active_and_category", using: :btree
  add_index "shop_tasks", ["active", "published", "expired_at", "user_id"], name: "by_active_and_published", using: :btree
  add_index "shop_tasks", ["active", "published", "is_top"], name: "by_active_and_is_top", using: :btree
  add_index "shop_tasks", ["active", "shop_type", "updated_at"], name: "by_active_and_updated_at", using: :btree

  create_table "shop_ticket_types", force: :cascade do |t|
    t.integer  "category_id",     limit: 4
    t.integer  "task_id",         limit: 4
    t.integer  "ticket_limit",    limit: 4,                           default: 0
    t.boolean  "is_limit"
    t.decimal  "original_fee",                precision: 8, scale: 2, default: 0.0
    t.decimal  "fee",                         precision: 8, scale: 2, default: 10.0
    t.boolean  "is_deleted",                                          default: false
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.string   "task_type",       limit: 255
    t.boolean  "is_each_limit"
    t.integer  "each_limit",      limit: 4,                           default: 0
    t.boolean  "active",                                              default: true
    t.string   "category",        limit: 255
    t.string   "second_category", limit: 255
  end

  add_index "shop_ticket_types", ["task_id", "task_type"], name: "by_task_id_and_task_type", using: :btree

  create_table "shop_topic_dynamics", force: :cascade do |t|
    t.text     "content",       limit: 65535
    t.integer  "user_id",       limit: 4
    t.integer  "shop_topic_id", limit: 4
    t.boolean  "active",                      default: true
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "comment_count", limit: 4,     default: 0
    t.integer  "like_count",    limit: 4,     default: 0
    t.integer  "foward_count",  limit: 4,     default: 0
  end

  create_table "shop_topics", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.boolean  "active",                           default: true
    t.text     "description",        limit: 65535
    t.string   "cover1",             limit: 255
    t.integer  "user_id",            limit: 4
    t.boolean  "is_share"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.string   "key",                limit: 255
    t.integer  "creator_id",         limit: 4
    t.string   "star_list",          limit: 255
    t.string   "guide",              limit: 255
    t.integer  "updater_id",         limit: 4
    t.string   "shop_category",      limit: 255,   default: "shop_topics"
    t.text     "kinder_description", limit: 65535
  end

  create_table "shop_videos", force: :cascade do |t|
    t.integer  "videoable_id",   limit: 4
    t.string   "videoable_type", limit: 255
    t.string   "key",            limit: 255
    t.integer  "user_id",        limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "shop_vote_options", force: :cascade do |t|
    t.integer  "voteable_id",   limit: 4
    t.string   "voteable_type", limit: 255
    t.string   "content",       limit: 255
    t.boolean  "active",                    default: true, null: false
    t.integer  "user_id",       limit: 4
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "shop_vote_options", ["user_id"], name: "by_user_id", using: :btree
  add_index "shop_vote_options", ["voteable_id"], name: "by_voteable_id", using: :btree

  create_table "shop_vote_results", force: :cascade do |t|
    t.integer  "shop_vote_option_id", limit: 4
    t.integer  "user_id",             limit: 4
    t.integer  "resource_id",         limit: 4
    t.string   "resource_type",       limit: 255
    t.boolean  "active",                          default: true, null: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  add_index "shop_vote_results", ["resource_id"], name: "by_resource_id", using: :btree
  add_index "shop_vote_results", ["shop_vote_option_id"], name: "by_option_id", using: :btree
  add_index "shop_vote_results", ["user_id"], name: "by_user_id", using: :btree

  create_table "tickets", force: :cascade do |t|
    t.string   "order_no",            limit: 255
    t.float    "payment",             limit: 24,    default: 0.0
    t.integer  "event_id",            limit: 4
    t.integer  "user_id",             limit: 4
    t.string   "name",                limit: 255
    t.string   "phone",               limit: 255
    t.string   "email",               limit: 255
    t.integer  "gender",              limit: 1
    t.string   "code",                limit: 255
    t.integer  "status",              limit: 4,     default: 1
    t.integer  "pay_type",            limit: 4,     default: 1
    t.integer  "quantity",            limit: 4,     default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "paid_at"
    t.datetime "canceled_at"
    t.string   "ext_info",            limit: 255
    t.string   "qr_code",             limit: 255
    t.datetime "checked_at"
    t.string   "qr_code_fingerprint", limit: 255
    t.datetime "deleted_at"
    t.datetime "paid_sms_sent_at"
    t.datetime "qr_code_created_at"
    t.string   "qr_path_cache",       limit: 255
    t.datetime "alipay_payment_at"
    t.integer  "address_id",          limit: 4
    t.integer  "trade_id",            limit: 4
    t.integer  "withdraw_ticket_id",  limit: 4
    t.integer  "event_owner_id",      limit: 4
    t.text     "memo",                limit: 65535
    t.string   "bank_code",           limit: 255
  end

  add_index "tickets", ["deleted_at", "trade_id"], name: "tickets_trade_id_index", using: :btree
  add_index "tickets", ["deleted_at"], name: "index_tickets_on_deleted_at", using: :btree
  add_index "tickets", ["event_id"], name: "index_tickets_on_event_id", using: :btree
  add_index "tickets", ["event_owner_id", "status", "paid_at"], name: "index_tickets_on_event_owner_id_and_status_and_paid_at", using: :btree
  add_index "tickets", ["event_owner_id"], name: "index_tickets_on_event_owner_id", using: :btree
  add_index "tickets", ["order_no"], name: "index_tickets_on_order_no", using: :btree
  add_index "tickets", ["paid_at"], name: "index_tickets_on_paid_at", using: :btree
  add_index "tickets", ["pay_type"], name: "index_tickets_on_pay_type", using: :btree
  add_index "tickets", ["phone"], name: "index_tickets_on_phone", using: :btree
  add_index "tickets", ["status"], name: "index_tickets_on_status", using: :btree
  add_index "tickets", ["user_id"], name: "index_tickets_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "nickname",               limit: 255,   default: "",    null: false
    t.string   "encrypted_password",     limit: 255,   default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,     default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "sex"
    t.integer  "area_id",                limit: 4
    t.text     "intro",                  limit: 65535
    t.string   "realname",               limit: 255
    t.string   "mobile",                 limit: 255
    t.datetime "verified_at"
    t.integer  "verified_user_id",       limit: 4
    t.boolean  "from_oauth",                           default: false
    t.string   "avatar",                 limit: 255
    t.string   "authentication_token",   limit: 255
    t.string   "uuid",                   limit: 255
    t.string   "email",                  limit: 255
    t.boolean  "notify_message",                       default: true
    t.string   "address",                limit: 255
    t.string   "aps_token",              limit: 255
    t.boolean  "aps_ignore",                           default: false
    t.string   "verify_info",            limit: 255
    t.string   "avatar_fingerprint",     limit: 255
    t.boolean  "watch",                                default: false
    t.datetime "deleted_at"
    t.boolean  "is_company",                           default: false
    t.boolean  "is_club",                              default: false
    t.boolean  "is_promoted",                          default: false
    t.string   "area_name",              limit: 255
    t.boolean  "is_talent",                            default: false
    t.string   "android_token",          limit: 255
    t.integer  "topics_count",           limit: 4,     default: 0
    t.integer  "updates_count",          limit: 4,     default: 0
    t.string   "wx_openid",              limit: 255
    t.integer  "jobs_count",             limit: 4,     default: 0
    t.string   "background_image",       limit: 255
    t.string   "domain",                 limit: 255
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
  add_index "users", ["email", "mobile"], name: "index_users_on_email_and_mobile", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["is_club"], name: "index_users_on_is_club", using: :btree
  add_index "users", ["is_company"], name: "index_users_on_is_company", using: :btree
  add_index "users", ["is_promoted"], name: "index_users_on_is_promoted", using: :btree
  add_index "users", ["jobs_count"], name: "index_users_on_jobs_count", using: :btree
  add_index "users", ["mobile"], name: "index_users_on_mobile", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uuid"], name: "index_users_on_uuid", using: :btree
  add_index "users", ["verify_info"], name: "index_users_on_verify_info", using: :btree

  create_table "welfare_events", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.string   "title",         limit: 255
    t.string   "descripe_key",  limit: 255
    t.text     "description",   limit: 65535
    t.datetime "sale_start_at"
    t.datetime "sale_end_at"
    t.string   "address",       limit: 255
    t.string   "mobile",        limit: 255
    t.string   "star_list",     limit: 255
    t.boolean  "active",                      default: true, null: false
    t.datetime "destroyed_at"
    t.integer  "creator_id",    limit: 4
    t.integer  "updater_id",    limit: 4
    t.integer  "lock_version",  limit: 4,     default: 0,    null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.datetime "start_at"
    t.datetime "end_at"
  end

  add_index "welfare_events", ["active", "title", "user_id", "mobile", "star_list"], name: "welfare_event_active", unique: true, using: :btree

  create_table "welfare_letter_images", force: :cascade do |t|
    t.integer  "letter_id",    limit: 4
    t.string   "key",          limit: 255
    t.string   "pic",          limit: 255
    t.boolean  "active",                   default: true, null: false
    t.integer  "lock_version", limit: 4,   default: 0,    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "welfare_letters", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.integer  "paper_id",     limit: 4
    t.string   "receiver",     limit: 255
    t.text     "content",      limit: 65535
    t.string   "signature",    limit: 255
    t.boolean  "active",                     default: true,  null: false
    t.integer  "lock_version", limit: 4,     default: 0,     null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "star_list",    limit: 255
    t.boolean  "is_share",                   default: false
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.integer  "user_id",      limit: 4
    t.string   "pic",          limit: 255
  end

  create_table "welfare_papers", force: :cascade do |t|
    t.string   "key",          limit: 255
    t.string   "pic",          limit: 255
    t.integer  "creator_id",   limit: 4
    t.integer  "updater_id",   limit: 4
    t.boolean  "published",                default: false, null: false
    t.boolean  "active",                   default: true,  null: false
    t.integer  "lock_version", limit: 4,   default: 0,     null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "welfare_products", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.string   "title",         limit: 255
    t.string   "descripe_key",  limit: 255
    t.text     "description",   limit: 65535
    t.datetime "sale_start_at"
    t.datetime "sale_end_at"
    t.string   "address",       limit: 255
    t.string   "mobile",        limit: 255
    t.string   "star_list",     limit: 255
    t.boolean  "active",                      default: true, null: false
    t.datetime "destroyed_at"
    t.integer  "creator_id",    limit: 4
    t.integer  "updater_id",    limit: 4
    t.integer  "lock_version",  limit: 4,     default: 0,    null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.datetime "start_at"
    t.datetime "end_at"
  end

  add_index "welfare_products", ["active", "title", "user_id", "mobile", "star_list"], name: "welfare_product_active", unique: true, using: :btree

  create_table "welfare_voices", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "key",        limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "pic_key",    limit: 255
    t.string   "duration",   limit: 255
    t.string   "title",      limit: 255
    t.string   "star_list",  limit: 255
    t.boolean  "active",                 default: true
  end

end
