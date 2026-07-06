xml.instruct! :xml, version: "1.0"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url { xml.loc root_url }
  xml.url { xml.loc cv_url }
  xml.url { xml.loc articles_url }

  @articles.each do |article|
    xml.url { xml.loc article_url(article.slug) }
  end
end
