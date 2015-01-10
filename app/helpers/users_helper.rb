module UsersHelper
  def rss_feed_url(user)
    if user.private && user.random_url
      id = user.random_key
    else
      id = user.id
    end

    url_for(
      :controller => :users,
      :action => :feeds,
      :id => id,
      :format => :rdf,
      :only_path => false
    )
  end

  def ics_feed_url(user, protocol = nil)
    if user.private && user.random_url
      id = user.random_key
    else
      id = user.id
    end

    url_for(
      :controller => :users,
      :action => :feeds,
      :id => id,
      :format => :ics,
      :only_path => false,
      :protocol => protocol
    )
  end
end
