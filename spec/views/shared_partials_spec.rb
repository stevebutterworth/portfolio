require "rails_helper"

RSpec.describe "Shared partials", type: :view do
  it "nav renders the ident mark and links" do
    render partial: "shared/nav"
    expect(rendered).to include("Steve Butterworth")
    expect(rendered).to include("//")
    expect(rendered).to include("Work")
  end

  it "footer renders the email obfuscated, never the raw address" do
    render partial: "shared/footer"
    expect(rendered).to include("stevebutterworth [at] me.com")
    expect(rendered).to include('data-controller="mailto"')
    expect(rendered).not_to include("stevebutterworth@me.com")
  end
end
