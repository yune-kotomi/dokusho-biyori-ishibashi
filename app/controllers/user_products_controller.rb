class UserProductsController < ApplicationController
  before_filter :login_required, :except => [:show]

  def create
    UserProduct.transaction do
      @product = Product.find(params[:product_id])

      user_products = @login_user.user_products.where(:product_id => @product.id)

      case params[:type_name]
      when 'ignore'
        if user_products.where(:type_name => 'ignore').count > 0
          bad_request
        else
          @user_product = user_products.where(:type_name => 'search').first
          if @user_product.present?
            @user_product.update_attribute(:type_name, 'ignore')
          else
            @user_product = @login_user.user_products.create(:type_name => 'ignore', :product_id => @product.id)
          end
        end

      when 'shelf'
        @user_product = user_products.where(:type_name => 'shelf').first
        if @user_product.present?
          bad_request
        else
          tags = JSON.parse(params[:tags])
          @user_product = @login_user.user_products.create(:type_name => 'shelf', :product_id => @product.id, :tags => tags)
        end

      else
        bad_request
      end
    end
  end

  def show
    @user = User.find(params[:id])
    if @user.private
      forbidden unless @user == @login_user
    end

    if params[:keyword].present?
      @user_products = UserProduct.search({:text => params[:keyword], :user_id => @user.id})
    else
      @user_products = @user.user_products.where(:type_name => 'shelf')
    end
    @user_products = @user_products.includes(:product)
  end

  def update
    @user_product = @login_user.user_products.find(params[:id])
    if @user_product.type_name == 'shelf'
      tags = JSON.parse(params[:tags])
      @user_product.update_attribute(:tags, tags)
    else
      bad_request
    end

  rescue ActiveRecord::RecordNotFound
    missing
  end

  def destroy
    @user_product = @login_user.user_products.find(params[:id])
    case @user_product.type_name
    when 'shelf'
      @user_product.destroy

    when 'ignore'
      @user_product.update_attribute(:type_name, 'search')
    end
  rescue ActiveRecord::RecordNotFound
    missing
  end
end
