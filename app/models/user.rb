class User < ActiveRecord::Base
  has_many :user_keywords
  has_many :user_products
  
  before_save :manage_key
  before_save :tags_to_json
  
  def tags
    if attributes['tags'].is_a?(String)
      JSON.parse(attributes['tags'])
    else
      attributes['tags']
    end
  end
  
  # tagsテーブルを更新する
  def update_tags(added, removed)
    current = tags
    
    added.each do |tag|
      if current[tag].present?
        current[tag] += 1
      else
        current[tag] = 1
      end
    end
    
    removed.each do |tag|
      if current[tag].present?
        if current[tag] == 1
          current.remove(tag)
        else
          current[tag] -= 1
        end
      end
    end
    
    self.tags = current
  end
  
  def search_user_products(keyword)
    
  end
  
  private
  def manage_key
    if self.changes.keys.include?('random_url')
      if random_url
        self.random_key = UUIDTools::UUID.random_create.to_s
      else
        self.random_key = nil
      end
    end
    
    if self.changes.keys.include?('private') and !private
      self.random_url = false
      self.random_key = nil
    end
  end
  
  def tags_to_json
    self.tags = tags.to_json
  end
end
