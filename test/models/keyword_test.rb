require 'test_helper'

class KeywordTest < ActiveSupport::TestCase
  setup do
    @keyword = keywords(:keyword1)
    
    @amazon = YAML.load(open('test/fixtures/amazon.txt').read)
    mock(Amazon).search(@keyword.value, @keyword.category, 1) { @amazon }
    
    @rakuten_books = YAML.load(open('test/fixtures/rakuten_books.txt').read)
    mock(RakutenBooks).search(@keyword.value, @keyword.category, 1) { @rakuten_books }
    
    @product = products(:keyword_search1)
    @product.put_to_fts
  end
  
  teardown do
    Groonga['Products'].each { |record| record.delete }
  end
  
  test "Amazonで検索後結果を保存して返す" do
    assert_difference 'Products.count', @amazon.last.size do
      pages, products = @keyword.amazon_search
    end
    
    assert_equal @amazon.first, pages
    assert_equal @amazon.last.size, products.size
  end
  
  test "楽天ブックスで検索後結果を保存して返す" do
    assert_difference 'Products.count', @rakuten_books.last.size do
      pages, products = @keyword.rakuten_search
    end
    
    assert_equal @rakuten_books.first, pages
    assert_equal @rakuten_books.last.size, products.size
  end
  
  test "groongaで検索後結果を返す" do
    assert_no_difference 'Products.count' do
      next_page, products = @keyword.search
    end
    
    assert !next_page
    assert_equal @product, products.first
  end
end

