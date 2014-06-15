class CreateUserKeywords < ActiveRecord::Migration
  def self.up
    create_table :user_keywords do |t|
      t.integer :user_id
      t.integer :keyword_id

      t.timestamps
    end
  end

  def self.down
    drop_table :user_keywords
  end
end
