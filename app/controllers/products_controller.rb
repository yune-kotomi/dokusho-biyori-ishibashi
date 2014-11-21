class ProductsController < ApplicationController

  # GET /products/1
  # GET /products/1.json
  def show
    @product = Product.where(:ean => params[:id]).first
  end
end
