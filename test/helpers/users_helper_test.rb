require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  include UsersHelper

  setup do
    @public = users(:user1)
    @private1 = users(:user2)
    @private2 = users(:user3)
  end

  test "公開ユーザのRSSフィードURLはユーザIDを含む" do
    actual = rss_feed_url(@public)
    expect = url_for(
      :controller => :users,
      :action => :feeds,
      :id => @public.id,
      :format => :rdf,
      :only_path => false
    )

    assert_equal expect, actual
  end

  test "ランダムURLが無効な非公開ユーザのRSSフィードURLはユーザIDを含む" do
    actual = rss_feed_url(@private1)
    expect = url_for(
      :controller => :users,
      :action => :feeds,
      :id => @private1.id,
      :format => :rdf,
      :only_path => false
    )

    assert_equal expect, actual
  end

  test "ランダムURLが有効な非公開ユーザのRSSフィードURLはランダムキーを含む" do
    actual = rss_feed_url(@private2)
    expect = url_for(
      :controller => :users,
      :action => :feeds,
      :id => @private2.random_key,
      :format => :rdf,
      :only_path => false
    )

    assert_equal expect, actual
  end


  test "公開ユーザのiCalendarフィードURLはユーザIDを含む" do
    actual = ics_feed_url(@public)
    expect = url_for(
      :controller => :users,
      :action => :feeds,
      :id => @public.id,
      :format => :ics,
      :only_path => false
    )

    assert_equal expect, actual
  end

  test "ランダムURLが無効な非公開ユーザのiCalendarフィードURLはユーザIDを含む" do
    actual = ics_feed_url(@private1)
    expect = url_for(
      :controller => :users,
      :action => :feeds,
      :id => @private1.id,
      :format => :ics,
      :only_path => false
    )

    assert_equal expect, actual
  end

  test "ランダムURLが有効な非公開ユーザのiCalendarフィードURLはランダムキーを含む" do
    actual = ics_feed_url(@private2)
    expect = url_for(
      :controller => :users,
      :action => :feeds,
      :id => @private2.random_key,
      :format => :ics,
      :only_path => false
    )

    assert_equal expect, actual
  end
end
