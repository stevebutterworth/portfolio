class PagesController < ApplicationController
  def home
    @projects = Project.all
  end

  def sitemap
  end
end
