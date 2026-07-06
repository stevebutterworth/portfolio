class ArticlesController < ApplicationController
  def index
    @articles = Article.all

    respond_to do |format|
      format.html
      format.rss
    end
  end

  def show
    @article = Article.find(params[:slug]) or raise ActionController::RoutingError, "not found"
  end
end
