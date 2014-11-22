class UsersController < ApplicationController
  def show
    @user = User.where(:domain_name => params[:domain_name], :screen_name => params[:screen_name]).first
    forbidden if @user.private? and @user != @login_user

    @user_products = @user.user_products.
      includes(:product).
      order('products.release_date desc').
      where(:type_name => 'search').
      offset(40 * (params[:page]|| 0).to_i).
      limit(41)

    product_id_list = @user_products.map{|user_product| user_product.product_id }
    @shelf_items = @user.user_products.
      where(:type_name => 'shelf').
      where("product_id in (?)", product_id_list)
  end

  def feeds
    begin
      @user = User.find(params[:id])

    rescue ActiveRecord::RecordNotFound
      @user = User.where(:random_key => params[:id]).first
    end

    if @user.present?
      if @user.private
        if @user.random_url == false or @user.random_key != params[:id]
          forbidden
        end
      end

      @user_products = @user.user_products.
        includes(:product).
        where(:type_name => 'search').
        offset(40 * (params[:page]|| 0).to_i).
        limit(41)
    else
      missing
    end
  end

  def login
    redirect_to Ishibashi::Application.config.authentication.start_authentication
  end

  def login_complete
    begin
      user_data = Ishibashi::Application.config.authentication.retrieve(params[:key], params[:timestamp], params[:signature])
      @user = User.where(:kitaguchi_profile_id => user_data['profile_id']).first
      if @user.nil?
        @user = User.new(
          :nickname => user_data['nickname'],
          :profile_text => user_data['profile_text']
        )
        @user.kitaguchi_profile_id = user_data['profile_id']
        @user.domain_name = user_data['domain_name']
        @user.screen_name = user_data['screen_name']
        @user.save

        # デフォルト出演者を投入
        cast = @user.casts.build
        cast.update_attribute(:character_id, Ishibashi::Application.config.default_character_id)

      else
        @user.update_attributes(
          :nickname => user_data['nickname'],
          :profile_text => user_data['profile_text']
        )
      end

      session[:user_id] = @user.id
      redirect_to :controller => :users, :action => :show, :domain_name => @user.domain_name, :screen_name => @user.screen_name

    rescue Hotarugaike::Profile::InvalidProfileExchangeError
      flash[:notice] = "ログインできませんでした"
      forbidden
    end
  end

  def logout
    session.delete(:user_id)

    redirect_to Ishibashi::Application.config.authentication.logout
  end

  def update
    if @login_user.present?
      @login_user.update(params[:user].permit(:private, :random_url))
      render :text => ({:status => 'ok'}).to_json
    else
      data = Ishibashi::Application.config.authentication.updated_profile(params)
      @user = User.where(:kitaguchi_profile_id => data['profile_id']).first
      if @user.present?
        @user.update_attributes(
          :nickname => data[:nickname],
          :profile_text => data[:profile_text]
        )
      end
      render :text => "success"
    end
  rescue Hotarugaike::Profile::InvalidProfileExchangeError
    forbidden
  end
end
