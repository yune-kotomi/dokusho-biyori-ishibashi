class AddProductPgroongaIndex < ActiveRecord::Migration
  def change
    Keyword::FTS_TARGETS.each do |c|
      add_index :products, c, :using => 'pgroonga'
    end
  end
end
