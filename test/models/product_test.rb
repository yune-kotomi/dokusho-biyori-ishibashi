require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  setup do
    @product = products(:product1)
    @product2 = products(:product2)
    @groonga = Groonga['Products']
    @amazon = YAML.load(open('test/fixtures/amazon.txt').read).last.first
    @rakuten_books = YAML.load(open('test/fixtures/rakuten_books.txt').read).last.first

    Product.all.each {|product| product.send(:save_to_fts) }
  end

  teardown do
    @groonga.each { |record| record.delete }
  end

  test "更新時にgroongaのインデックスを更新する" do
    new_title = 'product-test-title'
    assert_no_difference "@groonga.size" do
      @product.update_attribute(:a_title, new_title)
    end
    assert_equal 1, @groonga.select {|r| r.text =~ new_title }.size
  end

  test "Amazonの情報で自分自身を更新する" do
    mock(AmazonEcs).get(@product.ean) { @amazon }

    assert_no_difference "Product.count" do
      @product.update_with_amazon
      @product.save
    end
    assert_equal @amazon[:a_title], @product.a_title
  end

  test "楽天ブックスの情報で自分自身を更新する" do
    mock(RakutenBooks).get(@product.ean) { @rakuten_books }

    assert_no_difference "Product.count" do
      @product.update_with_rakuten_books
      @product.save
    end
    assert_equal @rakuten_books[:r_title], @product.r_title
  end

  test "関連商品を返す" do
    related = @product.related_products
    assert_equal @product2, related.first
  end
end
