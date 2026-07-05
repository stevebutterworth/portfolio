require "rails_helper"

RSpec.describe "smoke" do
  it "loads the Rails app and Commonmarker" do
    expect(Rails.application).to be_present
    expect(Commonmarker.to_html("**hi**")).to include("<strong>hi</strong>")
  end
end
