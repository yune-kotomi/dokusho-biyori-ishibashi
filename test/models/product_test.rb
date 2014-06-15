require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  setup do
    @product = products(:product1)
    
    @groonga = Groonga['Products']
    
    @amazon = YAML.load(open('test/fixtures/amazon_product.txt').read).last.first
    mock(Amazon).get(@product.ean) { @amazon }
    
    @rakuten_books = YAML.load(open('test/fixtures/rakuten_books_product.txt').read)
    mock(RakutenBooks).get(@product.ean) { @rakuten_books }
  end
  
  teardown do
    @groonga.each { |record| record.delete }
  end
  
  test "保存時にgroongaのインデックスを更新する" do
    product = Product.new(@product.attributes)
    assert_difference "@groonga.size" do
      product.save
    end
  end
  
  test "更新時にgroongaのインデックスを更新する" do
    new_title = 'product-test-title'
    assert_no_difference "@groonga.size" do
      @product.update_attribute(:title, new_title)
    end
    assert_equal 1, @groonga.select {|r| r.text =~ keyword }.size
  end
  
  test "Amazonの情報で自分自身を更新する" do
    assert_no_difference "Products.count" do
      @product.update_with_amazon
    end
    assert_equal @amazon[:title], @product.a_title
  end
  
  test "楽天ブックスの情報で自分自身を更新する" do
    assert_no_difference "Products.count" do
      @product.update_with_rakuten_books
    end
    assert_equal @rakuten_books[:title], @product.r_title
  end
  
end
