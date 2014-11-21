require 'test_helper'

class KeywordTest < ActiveSupport::TestCase
  setup do
    @keyword = keywords(:keyword1)

    @amazon = YAML.load(open('test/fixtures/amazon.txt').read)
    @rakuten_books = YAML.load(open('test/fixtures/rakuten_books.txt').read)

    @product = products(:keyword_search1)
    @product.send(:save_to_fts)
  end

  teardown do
    Groonga['Products'].each { |record| record.delete }
  end

  test "Amazonで検索後結果を保存して返す" do
    mock(AmazonEcs).search(@keyword.value, @keyword.category, 1) { @amazon }
    pages = 0
    products = []

    assert_difference 'Product.count', @amazon.last.size do
      pages, products = @keyword.amazon_search
    end

    assert_equal @amazon.first, pages
    assert_equal @amazon.last.size, products.size
  end

  test "楽天ブックスで検索後結果を保存して返す" do
    mock(RakutenBooks).search(@keyword.value, @keyword.category, 1) { @rakuten_books }
    pages = 0
    products = []

    assert_difference 'Product.count', @rakuten_books.last.size do
      pages, products = @keyword.rakuten_search
    end

    assert_equal @rakuten_books.first, pages
    assert_equal @rakuten_books.last.size, products.size
  end

  test "groongaで検索後結果を返す" do
    pages = 0
    products = []

    assert_no_difference 'Product.count' do
      pages, products = @keyword.search
    end

    assert_equal 1, pages
    assert_equal @product, products.first
  end

  test "新規保存時にはAmazon検索後Groongaで検索実行、keyword_productsを保存" do
    value = 'new keyword'
    category = 'books'
    mock(AmazonEcs).search(value, category, 1) { @amazon }
    keyword = Keyword.new(:value => value, :category => category)
    assert_difference 'Product.count', @amazon.last.size do
      assert_difference 'KeywordProduct.count', @amazon.last.size do
        keyword.save
      end
    end
  end
end
