require "rails_helper"

RSpec.describe Project do
  before do
    allow(described_class).to receive(:content_dir)
      .and_return(Rails.root.join("spec/fixtures/content/projects"))
  end

  describe ".all" do
    it "loads projects, ignores underscore files, orders by order then year desc" do
      expect(described_class.all.map(&:slug)).to eq(%w[alpha beta])
    end
  end

  describe ".find" do
    it "returns the project for a slug" do
      expect(described_class.find("alpha").title).to eq("Alpha")
    end

    it "returns nil for an unknown slug" do
      expect(described_class.find("nope")).to be_nil
    end
  end

  describe "an instance" do
    subject(:project) { described_class.find("alpha") }

    it "exposes typed fields" do
      expect(project.tech).to eq(%w[Rails Kafka])
      expect(project.gallery).to eq([ "projects/alpha/1.png" ])
      expect(project.videos).to eq([ "https://vimeo.com/1", "https://www.youtube.com/watch?v=abc123" ])
      expect(project.body_html).to include("<strong>Alpha</strong>")
    end

    it "is lightbox-eligible when it has gallery or video" do
      expect(project.lightbox?).to be(true)
      expect(described_class.find("beta").lightbox?).to be(false)
    end

    it "builds a delivered-for credit line, never client language" do
      expect(project.credit).to eq("Delivered for NTT DATA via LEX & Pulse Group")
      expect(described_class.find("beta").credit).to be_nil
    end
  end
end
