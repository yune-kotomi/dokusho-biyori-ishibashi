require 'test_helper'

class KeywordTest < ActiveSupport::TestCase
  setup do
    @keyword = keywords(:keyword1)

    @amazon = YAML.load(open('test/fixtures/amazon.txt').read)
    @rakuten_books = YAML.load(open('test/fixtures/rakuten_books.txt').read)

    @product = products(:keyword_search1)
    Product.all.each(&:save)
  end

  test "Amazonで検索後結果を保存して返す" do
    pages = 0
    products = []

    assert_difference 'Product.count', @amazon.last.size do
      AmazonEcs.stub(:search, @amazon) do
        pages, products = @keyword.amazon_search
      end
    end

    assert_equal @amazon.first, pages
    assert_equal @amazon.last.size, products.size
  end

  test "楽天ブックスで検索後結果を保存して返す" do
    pages = 0
    products = []

    assert_difference 'Product.count', @rakuten_books.last.size do
      RakutenBooks.stub(:search, @rakuten_books) do
        pages, products = @keyword.rakuten_search
      end
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
    keyword = Keyword.new(:value => value, :category => category)
    assert_difference 'Product.count', @amazon.last.size do
      assert_difference 'KeywordProduct.count', @amazon.last.size do
        AmazonEcs.stub(:search, @amazon) do
          keyword.save
        end
      end
    end
  end
end
