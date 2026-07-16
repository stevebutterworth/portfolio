require "rails_helper"

RSpec.describe "SEO", type: :request do
  describe "titles and meta tags" do
    it "sets the home page title, description and og tags with the first project's cover" do
      get "/"

      description = "Full-stack Rails engineer with over 20 years building, shipping and operating reliable web applications."
      expect(response.body).to include("<title>Steve Butterworth · Full-Stack Rails Engineer</title>")
      expect(response.body).to include(%(<meta name="description" content="#{description}">))
      expect(response.body).to include('<meta property="og:title" content="Steve Butterworth · Full-Stack Rails Engineer">')
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

    it "marks Contact active on /contact" do
      get "/contact"
      expect(response.body).to match(%r{<a href="/contact" class="[^"]*text-accent[^"]*">Contact</a>})
    end
  end

  describe "GET /sitemap.xml" do
    it "lists root and cv" do
      get "/sitemap.xml"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/xml")
      expect(response.body).to include("<loc>http://www.example.com/</loc>")
      expect(response.body).to include("<loc>http://www.example.com/cv</loc>")
    end
  end

  describe "GET /robots.txt" do
    it "allows all crawlers and points at the sitemap" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("User-agent: *")
      expect(response.body).to include("Allow: /")
      expect(response.body).to include("Sitemap: https://stevebutterworth.co.uk/sitemap.xml")
    end
  end
end
