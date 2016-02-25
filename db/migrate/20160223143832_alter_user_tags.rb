class AlterUserTags < ActiveRecord::Migration
  def change
    reversible do |r|
      r.up do
        rename_column :users, :tags, :tags_old
        add_column :users, :tags, :jsonb

        User.all.each do |user|
          user.update_attribute(:tags, user.tags_old)
        end

        remove_column :users, :tags_old
      end

      r.down do
        rename_column :users, :tags, :tags_old
        add_column :users, :tags, :text

        User.all.each do |user|
          user.update_attribute(:tags, user.tags_old.to_json)
        end

        remove_column :users, :tags_old
      end
    end
  end
end
