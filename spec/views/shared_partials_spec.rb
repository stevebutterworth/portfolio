require "rails_helper"

RSpec.describe "Shared partials", type: :view do
  it "nav renders the ident mark and links" do
    render partial: "shared/nav"
    expect(rendered).to include("Steve Butterworth")
    expect(rendered).to include("//")
    expect(rendered).to include("Work")
  end

  it "footer renders the email" do
    render partial: "shared/footer"
    expect(rendered).to include("hello@stevebutterworth.co.uk")
  end
end
