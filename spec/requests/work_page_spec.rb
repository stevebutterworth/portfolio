require "rails_helper"

RSpec.describe "Work page", type: :request do
  it "renders the hero and a row per project with credit and quote" do
    get "/"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Full-Stack Rails Engineer")
    expect(response.body).to include("I architect, build and operate reliable web applications.")
    expect(response.body).to include("Over 20 years of whole-product ownership")
    expect(response.body).not_to include("creative technologist")
    expect(response.body).not_to include("interactive installations")
    expect(response.body).to include("Selected work")
    expect(response.body).to include("interactive shot-by-shot tracker")
    expect(response.body).to include("Delivered for NTT DATA via LEX &amp; Pulse Group")
    expect(response.body).to include("flexible, proactive and collaborative")
  end

  it "keeps the portfolio shell capped and project covers 4:3" do
    get "/"
    expect(response.body).to include("max-w-7xl")
    expect(response.body).to include("portfolio-cover-frame relative aspect-[4/3] overflow-hidden")
    expect(response.body).to include("portfolio-cover h-full w-full object-cover")
  end

  it "uses the branded double-slash favicon" do
    get "/"
    expect(response.body).to include('href="/icon.svg?v=cobalt"')
    expect(response.body).to include('href="/icon.png?v=cobalt"')

    favicon = Nokogiri::XML(Rails.root.join("public/icon.svg").read)
    expect(favicon.xpath("//*[local-name()='path']").size).to eq(2)
    expect(favicon.xpath("//*[local-name()='circle']")).to be_empty
  end

  it "renders the other delivered-for strip at the bottom" do
    get "/"
    expect(response.body).to include("Also delivered projects for")
    expect(response.body).not_to include("Additional agency-led")
    expect(response.body).to include("British Airways")
    expect(response.body).not_to include("Yahoo")
    expect(response.body).not_to include("Castrol")
    expect(response.body).to include("St Modwen")
    expect(response.body).to include("Lenovo")
    expect(response.body).to include("Cambridge University Press")

    strip = response.body[/Also delivered projects for.*/m]
    expect(strip).not_to include("Emirates Airlines")
  end

  it "adds the lightbox controller only to projects with extra media" do
    get "/"
    # ntt-shotview has gallery+video; count of lightbox mounts equals lightbox-eligible projects
    eligible = Project.all.count(&:lightbox?)
    expect(response.body.scan('data-controller="lightbox"').size).to eq(eligible)
    expect(response.body).to include("4 images · 2 videos")
    expect(response.body).not_to include("&#9635;")
  end
end
