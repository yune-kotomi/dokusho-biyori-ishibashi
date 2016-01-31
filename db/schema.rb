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

ActiveRecord::Schema.define(version: 20141220124917) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "keyword_products", force: :cascade do |t|
    t.integer  "keyword_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "keyword_products", ["product_id"], name: "index_keyword_products_on_product_id", using: :btree

  create_table "keywords", force: :cascade do |t|
    t.string   "value",      limit: 255
    t.string   "category",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: :cascade do |t|
    t.string   "ean",                  limit: 255
    t.string   "category",             limit: 255
    t.text     "a_title"
    t.text     "a_authors_json"
    t.text     "a_manufacturer"
    t.text     "a_image_medium"
    t.text     "a_image_small"
    t.text     "a_url"
    t.datetime "a_release_date"
    t.boolean  "a_release_date_fixed",             default: true
    t.text     "r_title"
    t.text     "r_authors"
    t.text     "r_manufacturer"
    t.text     "r_image_medium"
    t.text     "r_image_small"
    t.text     "r_url"
    t.datetime "r_release_date"
    t.text     "title"
    t.datetime "release_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "products", ["ean"], name: "products_ean", using: :btree

  create_table "user_keywords", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "keyword_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_products", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "product_id"
    t.string   "type_name",  limit: 255, default: "search"
    t.text     "tags_json",              default: "[]"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_products", ["product_id"], name: "index_user_products_on_product_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "domain_name",          limit: 255
    t.string   "screen_name",          limit: 255
    t.string   "nickname",             limit: 255
    t.text     "profile_text"
    t.integer  "kitaguchi_profile_id"
    t.boolean  "random_url",                       default: false
    t.string   "random_key",           limit: 255
    t.boolean  "private"
    t.text     "tags",                             default: "{}"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
