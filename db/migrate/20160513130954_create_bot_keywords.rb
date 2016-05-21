class CreateBotKeywords < ActiveRecord::Migration
  def change
    create_table :bot_keywords do |t|
      t.integer :notify_at
      t.boolean :uncertain, :default => false
      t.string :tweet_id
      t.string :twitter_user_id

      t.integer :bot_user_id
      t.integer :user_keyword_id

      t.timestamps null: false
    end
  end
end
