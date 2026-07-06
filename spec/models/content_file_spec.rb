require "rails_helper"

RSpec.describe ContentFile do
  let(:path) { Rails.root.join("spec/fixtures/content/sample.md") }
  subject(:file) { described_class.new(path) }

  it "parses front-matter into a string-keyed hash" do
    expect(file.data).to eq("title" => "Sample", "tags" => [ "Rails", "Hotwire" ])
  end

  it "exposes the markdown body without the front-matter" do
    expect(file.body_markdown.strip).to eq("Hello **world**.")
  end

  it "renders the body to HTML" do
    expect(file.body_html).to include("<strong>world</strong>")
  end

  it "reflows soft-wrapped source lines instead of hard-breaking them" do
    wrapped = Rails.root.join("spec/fixtures/content/wrapped.md")
    File.write(wrapped, "one line\nwrapped for readability")
    expect(described_class.new(wrapped).body_html).not_to include("<br")
  ensure
    File.delete(wrapped) if wrapped.exist?
  end

  it "renders GitHub-flavored markdown extensions" do
    gfm = Rails.root.join("spec/fixtures/content/gfm.md")
    File.write(gfm, "~~struck~~")
    expect(described_class.new(gfm).body_html).to include("<del>struck</del>")
  ensure
    File.delete(gfm) if gfm.exist?
  end

  it "knows whether its file exists" do
    expect(file.exists?).to be(true)
    expect(described_class.new(Rails.root.join("spec/fixtures/content/missing.md")).exists?).to be(false)
  end

  it "returns an empty hash when there is no front-matter" do
    plain = Rails.root.join("spec/fixtures/content/plain.md")
    File.write(plain, "Just text.")
    expect(described_class.new(plain).data).to eq({})
  ensure
    File.delete(plain) if plain.exist?
  end
end
