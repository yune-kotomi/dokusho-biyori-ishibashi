class UserProduct < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
  
  before_save :update_user_tags
  
  def tags
    JSON.parse(tags_json)
  end
  
  def tags=(value)
    self.tags_json = value.to_json
  end
  
  private
  def save_to_fts
    table = Groonga['UserProducts']
    record = table[self.id.to_s]
    text = tags.collect{|e| "[#{e}]" }.join
    if record.present?
      record['text'] = text
    else
      table.add(self.id.to_s, :text => text, :user_id => self.user_id)
    end
  end
  
  def update_user_tags
    if tags_json.tags_json_change
      previous = JSON.parse(tags_json.tags_json_change.first)
      current = JSON.parse(tags_json.tags_json_change.last)
      added = current - previous
      removed = previous - current
      user.update_tags(added, removed)
      user.save
    end
  end
end
