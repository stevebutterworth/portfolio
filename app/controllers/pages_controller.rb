class PagesController < ApplicationController
  def home
    @projects = Project.all
  end

  def sitemap
    @articles = Article.all
  end
end
