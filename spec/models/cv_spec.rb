require "rails_helper"

RSpec.describe Cv do
  before do
    allow(described_class).to receive(:content_path)
      .and_return(Rails.root.join("spec/fixtures/content/cv.yml"))
  end

  subject(:cv) { described_class.load }

  it "exposes typed fields from the yaml" do
    expect(cv.name).to eq("Ada Example")
    expect(cv.title).to eq("Senior Example Engineer")
    expect(cv.tagline).to eq("Ruby · Testing · SQLite")
    expect(cv.location).to eq("Testville")
    expect(cv.email).to eq("ada@example.com")
    expect(cv.linkedin).to eq("https://linkedin.com/in/ada")
    expect(cv.github).to eq("https://github.com/ada")
    expect(cv.education).to eq("BSc Example")
    expect(cv.profile).to include("Profile text for testing purposes")
  end

  it "exposes skills as a hash" do
    expect(cv.skills).to eq({ "Backend" => "Ruby, Rails", "Data" => "SQLite, testing" })
  end

  it "exposes jobs as an array of hashes with string keys, engagements nested" do
    expect(cv.jobs.size).to eq(2)
    expect(cv.jobs.first["role"]).to eq("Engineer")
    expect(cv.jobs.first["org"]).to eq("Acme")
    expect(cv.jobs.last["engagements"]).to be_an(Array)
    expect(cv.jobs.last["engagements"].first["org"]).to eq("Widgets Inc")
  end

  it "exposes additional experience as an array of hashes" do
    expect(cv.additional.first["role"]).to eq("Volunteer")
    expect(cv.additional.first["org"]).to eq("Community Group")
  end

  describe "#to_markdown" do
    subject(:markdown) { cv.to_markdown }

    it "opens with name, title and a contact line, never an em-dash" do
      lines = markdown.lines.map(&:chomp)
      expect(lines[0]).to eq("# Ada Example")
      expect(lines[1]).to eq("Senior Example Engineer")
      expect(lines[2]).to include("Testville")
      expect(lines[2]).to include("ada@example.com")
      expect(lines[2]).to include("https://linkedin.com/in/ada")
      expect(lines[2]).to include("https://github.com/ada")
      expect(markdown).not_to include("—")
    end

    it "includes a profile section" do
      expect(markdown).to include("## Profile")
      expect(markdown).to include("Profile text for testing purposes")
    end

    it "lists core skills, one bold category bullet per line" do
      expect(markdown).to include("## Core skills")
      expect(markdown).to include("- **Backend:** Ruby, Rails")
      expect(markdown).to include("- **Data:** SQLite, testing")
    end

    it "renders experience with role, org, when headers, context and bullets" do
      expect(markdown).to include("## Experience")
      expect(markdown).to include("### Engineer, Acme (2020 - Present)")
      expect(markdown).to include("Widget manufacturing")
      expect(markdown).to include("- Did a thing.")
      expect(markdown).to include("- Did another thing.")
    end

    it "nests engagements under their parent job as level-4 headers" do
      expect(markdown).to include("### Consultant, Flumes (2015 - 2020)")
      expect(markdown).to include("#### Contractor, Widgets Inc (2016 - 2018)")
      expect(markdown).to include("Engaged via Agency")
      expect(markdown).to include("- Built widgets.")
      expect(markdown).to include("- Fixed widgets.")
    end

    it "includes additional experience" do
      expect(markdown).to include("## Additional experience")
      expect(markdown).to include("### Volunteer, Community Group (2019 - Present)")
      expect(markdown).to include("- Volunteered.")
    end
  end
end
