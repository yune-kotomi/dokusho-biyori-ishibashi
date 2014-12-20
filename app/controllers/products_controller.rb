class ProductsController < ApplicationController

  # GET /products/1
  # GET /products/1.json
  def show
    @product = Product.where(:ean => params[:id]).first
  end

  def to_amazon
    show
    redirect_to @product.a_url
  end

  def to_rakuten
    show
    redirect_to @product.r_url
  end
end
