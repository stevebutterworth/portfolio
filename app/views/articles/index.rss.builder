xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Steve Butterworth · Writing"
    xml.link articles_url
    xml.description "Essays on Rails, data-heavy systems, and shipping software that has to run in the wild on the night."
    xml.language "en"

    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.link article_url(article.slug)
        xml.guid article_url(article.slug)
        xml.pubDate article.date.to_time.rfc2822
        xml.description article.excerpt
      end
    end
  end
end
