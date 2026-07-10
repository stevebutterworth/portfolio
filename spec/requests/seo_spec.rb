require "rails_helper"

RSpec.describe "SEO", type: :request do
  describe "titles and meta tags" do
    it "sets the home page title, description and og tags with the first project's cover" do
      get "/"

      description = "Senior product engineer and Ruby on Rails specialist with over 20 years building, shipping and operating reliable web applications."
      expect(response.body).to include("<title>Steve Butterworth · Senior Product Engineer</title>")
      expect(response.body).to include(%(<meta name="description" content="#{description}">))
      expect(response.body).to include('<meta property="og:title" content="Steve Butterworth · Senior Product Engineer">')
      expect(response.body).to include(%(<meta property="og:description" content="#{description}">))
      expect(response.body).to include('<meta property="og:type" content="website">')
      expect(response.body).to include('<meta name="twitter:card" content="summary_large_image">')

      cover = Project.all.first.cover
      expect(response.body).to include(%(<meta property="og:image" content="http://www.example.com/media/#{cover}">))
    end

    it "sets the cv page title and og:title" do
      get "/cv"

      expect(response.body).to include("<title>CV · Steve Butterworth</title>")
      expect(response.body).to include('<meta property="og:title" content="CV · Steve Butterworth">')
    end

    it "sets the writing index title and og:title" do
      get "/writing"

      expect(response.body).to include("<title>Writing · Steve Butterworth</title>")
      expect(response.body).to include('<meta property="og:title" content="Writing · Steve Butterworth">')
    end

    it "sets the article title, og:type article and its own cover as og:image" do
      article = Article.all.first
      get "/writing/#{article.slug}"

      expect(response.body).to include("<title>#{article.title} · Steve Butterworth</title>")
      expect(response.body).to include(%(<meta property="og:title" content="#{article.title} · Steve Butterworth">))
      expect(response.body).to include('<meta property="og:type" content="article">')
      expect(response.body).to include(%(<meta property="og:image" content="http://www.example.com/media/#{article.cover}">))
    end

    it "sets the contact page title and og:title" do
      get "/contact"

      expect(response.body).to include("<title>Contact · Steve Butterworth</title>")
      expect(response.body).to include('<meta property="og:title" content="Contact · Steve Butterworth">')
    end
  end

  describe "nav active states" do
    it "marks Work active on / only" do
      get "/"
      expect(response.body).to match(%r{<a href="/" class="[^"]*text-accent[^"]*">Work</a>})

      get "/cv"
      expect(response.body).not_to match(%r{<a href="/" class="[^"]*text-accent[^"]*">Work</a>})
    end

    it "marks CV active on /cv" do
      get "/cv"
      expect(response.body).to match(%r{<a href="/cv" class="[^"]*text-accent[^"]*">CV</a>})
    end

    it "marks Writing active on /writing and stays active on an article page" do
      get "/writing"
      expect(response.body).to match(%r{<a href="/writing" class="[^"]*text-accent[^"]*">Writing</a>})

      article = Article.all.first
      get "/writing/#{article.slug}"
      expect(response.body).to match(%r{<a href="/writing" class="[^"]*text-accent[^"]*">Writing</a>})
    end

    it "marks Contact active on /contact" do
      get "/contact"
      expect(response.body).to match(%r{<a href="/contact" class="[^"]*text-accent[^"]*">Contact</a>})
    end
  end

  describe "GET /sitemap.xml" do
    it "lists root, cv, writing and every article url" do
      get "/sitemap.xml"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/xml")
      expect(response.body).to include("<loc>http://www.example.com/</loc>")
      expect(response.body).to include("<loc>http://www.example.com/cv</loc>")
      expect(response.body).to include("<loc>http://www.example.com/writing</loc>")

      Article.all.each do |article|
        expect(response.body).to include("<loc>http://www.example.com/writing/#{article.slug}</loc>")
      end
    end
  end

  describe "GET /robots.txt" do
    it "allows all crawlers and points at the sitemap" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("User-agent: *")
      expect(response.body).to include("Allow: /")
      expect(response.body).to include("Sitemap: https://steveb.io/sitemap.xml")
    end
  end
end
