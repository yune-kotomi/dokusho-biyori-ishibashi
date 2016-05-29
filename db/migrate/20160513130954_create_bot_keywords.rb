class CreateBotKeywords < ActiveRecord::Migration
  def change
    create_table :bot_keywords do |t|
      t.integer :notify_at
      t.boolean :uncertain, :default => false
      t.string :tweet_id
      t.string :twitter_user_id
      t.string :twitter_user_screen_name
      t.integer :sent_keyword_product_id, :array => true, :default => '{}'

      t.integer :user_keyword_id

      t.timestamps null: false
    end
  end
end
