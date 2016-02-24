require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  setup do
    @product = products(:product1)
    @product2 = products(:product2)
    @amazon = YAML.load(open('test/fixtures/amazon.txt').read).last.first
    @rakuten_books = YAML.load(open('test/fixtures/rakuten_books.txt').read).last.first
  end

  test "Amazonの情報で自分自身を更新する" do
    mock(AmazonEcs).get(@product.ean) { @amazon }

    assert_no_difference "Product.count" do
      @product.update_with_amazon
      @product.save
    end
    assert_equal @amazon[:a_title], @product.a_title
    assert_equal @amazon[:category], @product.category
    assert_equal @amazon[:ean], @product.ean
  end

  test "楽天ブックスの情報で自分自身を更新する" do
    mock(RakutenBooks).get(@product.ean) { @rakuten_books }

    assert_no_difference "Product.count" do
      @product.update_with_rakuten_books
      @product.save
    end
    assert_equal @rakuten_books[:r_title], @product.r_title
    assert_equal @rakuten_books[:ean], @product.ean
  end

  test "関連商品を返す" do
    related = @product.related_products
    assert_equal @product2, related.first
  end

  test 'Amazon画像のSSL化' do
    uri = URI(@product.image_small)
    assert_equal 'https', uri.scheme
    assert_equal 'images-na.ssl-images-amazon.com', uri.host

    uri = URI(@product.image_medium)
    assert_equal 'https', uri.scheme
    assert_equal 'images-na.ssl-images-amazon.com', uri.host
  end

  test '楽天ブックス画像のSSL化' do
    uri = URI(@product2.image_small)
    assert_equal 'https', uri.scheme

    uri = URI(@product2.image_medium)
    assert_equal 'https', uri.scheme
  end
end
