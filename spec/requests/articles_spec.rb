require "rails_helper"

RSpec.describe "Articles", type: :request, skip: "Writing is disabled until real posts are published" do
  describe "GET /writing" do
    it "lists all articles with meta line, title, excerpt and tags" do
      get "/writing"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Notes from the build.")

      Article.all.each do |article|
        expect(response.body).to include(article.title)
        expect(response.body).to include(article.excerpt)
        expect(response.body).to include(article.date.strftime("%-d %b %Y"))
        expect(response.body).to include("#{article.reading_time} min read")
        article.tags.each { |tag| expect(response.body).to include(tag) }
      end
    end
  end

  describe "GET /writing/:slug" do
    it "renders the post with title, excerpt deck and a prose body with code styling" do
      article = Article.all.first
      get "/writing/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(article.title)
      expect(response.body).to include(article.excerpt)
      expect(response.body).to include("prose-post")
      expect(response.body).to include("<pre")
    end

    it "404s for an unknown slug" do
      get "/writing/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /writing.rss" do
    it "responds with rss xml listing both articles" do
      get "/writing.rss"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/rss+xml")
      expect(response.body).to include("Steve Butterworth")

      Article.all.each do |article|
        expect(response.body).to include(article.title)
      end
    end
  end
end
