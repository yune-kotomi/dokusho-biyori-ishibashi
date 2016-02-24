class UserProduct < ActiveRecord::Base
  belongs_to :user
  belongs_to :product

  before_save :update_user_tags

  private
  def update_user_tags
    if self.tags_change
      previous = self.tags_change.first || []
      current = self.tags_change.last || []
      added = current - previous
      removed = previous - current
      user.update_tags(added, removed)
      user.save
    end
  end
end
