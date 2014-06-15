class KeywordProduct < ActiveRecord::Base
  belongs_to :keyword
  belongs_to :product
end
