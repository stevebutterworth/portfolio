require "rails_helper"

RSpec.describe "Lightbox", type: :system do
  before { driven_by(:selenium_chrome_headless) }

  it "opens on cover click and closes on Escape" do
    visit "/"
    first('[data-controller="lightbox"] [data-lightbox-target="cover"]').click
    expect(page).to have_css(".lightbox-overlay", visible: :visible)
    expect(page).to have_css(".lightbox-counter")
    find("body").send_keys(:escape)
    expect(page).to have_no_css(".lightbox-overlay")
  end
end
