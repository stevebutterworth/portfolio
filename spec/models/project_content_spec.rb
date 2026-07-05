require "rails_helper"

RSpec.describe "Real project content" do
  it "loads eight projects in curated order" do
    slugs = Project.all.map(&:slug)
    expect(slugs).to eq(%w[ntt-shotview environmentjob emirates gsk-mvoc indy-500 changeflow team-gb trackly])
  end

  it "points every cover at a file that exists in public/media" do
    Project.all.each do |project|
      cover = Rails.root.join("public/media", project.cover)
      expect(cover).to exist, "missing cover for #{project.slug}: #{cover}"
    end
  end

  it "keeps agency credits, not client language" do
    expect(Project.find("ntt-shotview").credit).to eq("Delivered for NTT DATA via LEX & Pulse Group")
    expect(Project.find("changeflow").credit).to be_nil
  end
end
