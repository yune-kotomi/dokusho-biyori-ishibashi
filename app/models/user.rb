class User < ActiveRecord::Base
  has_many :user_keywords
  has_many :user_products

  before_save :manage_key

  def tag_table
    JSON.parse(self.tags)
  end

  def tag_table=(value)
    self.tags = value.to_json
  end

  # tagsテーブルを更新する
  def update_tags(added, removed)
    current = tag_table

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
          current.delete(tag)
        else
          current[tag] -= 1
        end
      end
    end

    self.tag_table = current
  end

  def search_user_products(keyword)
    UserProduct.search(:text => keyword, :user_id => self.id)
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
end
