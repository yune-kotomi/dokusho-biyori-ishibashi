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
        UserProduct.transaction do
          @user_product = user_products.where(:type_name => 'shelf').first
          if @user_product.present?
            tags = JSON.parse(params[:tags])
            @user_product.update_attribute(:tags, tags)
          else
            tags = JSON.parse(params[:tags])
            @user_product = @login_user.user_products.create(:type_name => 'shelf', :product_id => @product.id, :tags => tags)
          end
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

    @user_products = @user.user_products.where(:type_name => 'shelf')
    if params[:keyword].present?
      keywords = Shellwords.shellwords(params[:keyword])
      @user_products = @user_products.where('user_products.tags @> ARRAY[?]::varchar[]', keywords)
    end

    @user_products =
      @user_products.includes(:product).
      order('user_products.updated_at desc').
      offset(offset).
      limit(41)
  end

  def destroy
    UserProduct.transaction do
      @user_product = @login_user.user_products.where(:id => params[:id], :type_name => params[:type_name]).first
      if @user_product.present?
        case @user_product.type_name
        when 'shelf'
          @user_product.destroy

        when 'ignore'
          @user_product.update_attribute(:type_name, 'search')
        end
      else
        missing
      end
    end
  end
end
