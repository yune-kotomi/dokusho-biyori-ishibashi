class AddProductsFulltext < ActiveRecord::Migration
  def change
    add_column :products, :fulltext, :text
    add_index :products, :fulltext, :using => 'pgroonga'

    [:title, :authors, :manufacturer].
      flat_map{|s| ["a_#{s}", "r_#{s}"] }.
      map(&:to_sym).
      each{|c| remove_index :products, c }
  end
end
