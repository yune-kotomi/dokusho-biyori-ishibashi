class CreateKeywordCandicates < ActiveRecord::Migration
  def change
    create_table :keyword_candicates do |t|
      t.text :value
      t.string :category
      t.text :elements, :array => true

      t.timestamps null: false
    end

    add_index :keyword_candicates, :value, :using => 'pgroonga'
  end
end
