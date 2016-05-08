class ChangeColumnToProduct < ActiveRecord::Migration
  def change
    change_column :products, :a_authors, :text, :array => true
    change_column :products, :r_authors, :text, :array => true
  end
end
