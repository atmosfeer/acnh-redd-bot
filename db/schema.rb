# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_06_11_165242) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "announcements", force: :cascade do |t|
    t.bigint "discord_id"
    t.string "content"
    t.bigint "user_id"
    t.bigint "channel_id"
    t.string "dodo"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["channel_id"], name: "index_announcements_on_channel_id"
    t.index ["user_id"], name: "index_announcements_on_user_id"
  end

  create_table "art_pieces", force: :cascade do |t|
    t.string "name"
    t.integer "number"
    t.string "status"
    t.bigint "announcement_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["announcement_id"], name: "index_art_pieces_on_announcement_id"
    t.index ["user_id"], name: "index_art_pieces_on_user_id"
  end

  create_table "channels", force: :cascade do |t|
    t.bigint "discord_id"
    t.string "discord_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "reactions", force: :cascade do |t|
    t.integer "number"
    t.bigint "announcement_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["announcement_id"], name: "index_reactions_on_announcement_id"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "discord_id"
    t.string "discord_name"
    t.boolean "in_queue", default: false
    t.boolean "active_post", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
