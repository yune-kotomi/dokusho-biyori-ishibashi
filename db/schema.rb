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

ActiveRecord::Schema.define(version: 20160508070550) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pgroonga"

  create_table "keyword_products", force: :cascade do |t|
    t.integer  "keyword_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "keyword_products", ["product_id"], name: "index_keyword_products_on_product_id", using: :btree

  create_table "keywords", force: :cascade do |t|
    t.string   "value"
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: :cascade do |t|
    t.string   "ean"
    t.string   "category"
    t.text     "a_title"
    t.text     "a_authors_json"
    t.text     "a_manufacturer"
    t.text     "a_image_medium"
    t.text     "a_image_small"
    t.text     "a_url"
    t.datetime "a_release_date"
    t.boolean  "a_release_date_fixed", default: true
    t.text     "r_title"
    t.text     "r_authors_old"
    t.text     "r_manufacturer"
    t.text     "r_image_medium"
    t.text     "r_image_small"
    t.text     "r_url"
    t.datetime "r_release_date"
    t.datetime "release_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "a_authors",                           array: true
    t.text     "r_authors",                           array: true
  end

  add_index "products", ["a_authors"], name: "index_products_on_a_authors", using: :pgroonga
  add_index "products", ["a_manufacturer"], name: "index_products_on_a_manufacturer", using: :pgroonga
  add_index "products", ["a_title"], name: "index_products_on_a_title", using: :pgroonga
  add_index "products", ["ean"], name: "products_ean", using: :btree
  add_index "products", ["r_authors"], name: "index_products_on_r_authors", using: :pgroonga
  add_index "products", ["r_manufacturer"], name: "index_products_on_r_manufacturer", using: :pgroonga
  add_index "products", ["r_title"], name: "index_products_on_r_title", using: :pgroonga

  create_table "user_keywords", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "keyword_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_products", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "product_id"
    t.string   "type_name",  default: "search"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tags",                          array: true
  end

  add_index "user_products", ["product_id"], name: "index_user_products_on_product_id", using: :btree
  add_index "user_products", ["tags"], name: "index_user_products_on_tags", using: :gin

  create_table "users", force: :cascade do |t|
    t.string   "domain_name"
    t.string   "screen_name"
    t.string   "nickname"
    t.text     "profile_text"
    t.integer  "kitaguchi_profile_id"
    t.boolean  "random_url",           default: false
    t.string   "random_key"
    t.boolean  "private",              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb    "tags"
  end

end
