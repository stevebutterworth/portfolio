require "rails_helper"

RSpec.describe "Work page", type: :request do
  it "renders the hero and a row per project with credit and quote" do
    get "/"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Selected work")
    expect(response.body).to include("ShotView, The Open")
    expect(response.body).to include("Delivered for NTT DATA via LEX &amp; Pulse Group")
    expect(response.body).to include("Placeholder testimonial")
  end

  it "adds the lightbox controller only to projects with extra media" do
    get "/"
    # ntt-shotview has gallery+video; count of lightbox mounts equals lightbox-eligible projects
    eligible = Project.all.count(&:lightbox?)
    expect(response.body.scan('data-controller="lightbox"').size).to eq(eligible)
  end
end
