class KeywordsController < ApplicationController
  before_filter :login_required

  # GET /keywords
  # GET /keywords.json
  def index
    @user_keywords = @login_user.user_keywords.includes(:keyword).group_by{|u_k| u_k.keyword.category}
  end

  # POST /keywords
  # POST /keywords.json
  def create
    Keyword.transaction do
      @keyword = Keyword.where(:value => params[:keyword][:value], :category => params[:keyword][:category]).first
      if @keyword.blank?
        @keyword = Keyword.new(params[:keyword].permit(:value, :category))
        @keyword.save
      end

      if @keyword.user_keywords.where(:user_id => @login_user.id).count > 0
        forbidden
      else
        @user_keyword = @keyword.user_keywords.create(:user_id => @login_user.id)
      end
    end
  end

  # DELETE /keywords/1
  # DELETE /keywords/1.json
  def destroy
    UserKeyword.transaction do
      begin
        @user_keyword = @login_user.user_keywords.find(params[:id])
        @keyword = @user_keyword.keyword
        @user_keyword.destroy
        @keyword.destroy if @keyword.user_keywords.count == 0

      rescue ActiveRecord::RecordNotFound
        missing
      end
    end
  end
end
