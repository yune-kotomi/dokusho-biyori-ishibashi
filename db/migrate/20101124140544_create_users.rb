class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :domain_name
      t.string :screen_name
      t.string :nickname
      t.text :profile_text
      t.integer :kitaguchi_profile_id
      t.boolean :random_url, :default => false
      t.string :random_key
      t.boolean :private, :default => false
      t.text :tags, :default => "{}"

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
