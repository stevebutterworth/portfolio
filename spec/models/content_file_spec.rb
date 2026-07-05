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

  it "returns an empty hash when there is no front-matter" do
    plain = Rails.root.join("spec/fixtures/content/plain.md")
    File.write(plain, "Just text.")
    expect(described_class.new(plain).data).to eq({})
  ensure
    File.delete(plain) if plain.exist?
  end
end
