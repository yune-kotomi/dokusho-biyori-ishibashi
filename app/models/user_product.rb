class UserProduct < ActiveRecord::Base
  belongs_to :user
  belongs_to :product

  before_save :update_user_tags
  after_save :save_to_fts
  after_destroy :remove_from_fts

  def tags
    JSON.parse(tags_json)
  end

  def tags=(value)
    self.tags_json = value.to_json
  end

  def self.search(params)
    table = Groonga['UserProducts']
    keywords = Shellwords.shellwords(params[:text])
    ids = table.select do |r|
      grn = keywords.map{|keyword| r.text =~ keyword }
      grn.push(r.user_id == params[:user_id])
      grn
    end.collect{|r| r.key.key }
    where(:id => ids)
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
    if self.tags_json_change
      previous = JSON.parse(self.tags_json_change.first)
      current = JSON.parse(self.tags_json_change.last)
      added = current - previous
      removed = previous - current
      user.update_tags(added, removed)
      user.save
    end
  end

  def remove_from_fts
    table = Groonga['UserProducts']
    record = table[self.id.to_s]
    record.delete if record.present?
  end
end
