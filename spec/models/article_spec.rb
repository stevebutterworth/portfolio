require "rails_helper"

RSpec.describe Article do
  before do
    allow(described_class).to receive(:content_dir)
      .and_return(Rails.root.join("spec/fixtures/content/posts"))
  end

  describe ".all" do
    it "loads articles, ignores underscore files, orders by front matter date desc" do
      # Filenames are deliberately out of date order (alpha's filename date is
      # earliest, beta's is latest) to prove sorting uses the front matter
      # date field, not the filename prefix. The _draft.md fixture has no
      # date prefix at all and must never show up here.
      expect(described_class.all.map(&:slug)).to eq(%w[alpha-post gamma-post beta-post])
    end
  end

  describe ".find" do
    it "returns the article for a slug parsed from the dated filename" do
      expect(described_class.find("alpha-post").title).to eq("Alpha Post")
    end

    it "returns nil for an unknown slug" do
      expect(described_class.find("nope")).to be_nil
    end
  end

  describe "an instance" do
    subject(:article) { described_class.find("alpha-post") }

    it "parses the slug from the filename, stripping the date prefix and extension" do
      expect(article.slug).to eq("alpha-post")
    end

    it "exposes the front matter date as a Date, independent of the filename date" do
      expect(article.date).to eq(Date.new(2026, 6, 20))
      expect(article.date).to be_a(Date)
    end

    it "exposes typed fields" do
      expect(article.title).to eq("Alpha Post")
      expect(article.author).to eq("Jane Doe")
      expect(article.tags).to eq(%w[Rails SQLite])
      expect(article.excerpt).to eq("An excerpt for alpha.")
      expect(article.thumbnail).to eq("posts/alpha-post/thumb.jpg")
      expect(article.cover).to eq("posts/alpha-post/hero.jpg")
      expect(article.body_html).to include("<h2>")
    end

    it "defaults the author to Steve Butterworth when the front matter omits it" do
      expect(described_class.find("beta-post").author).to eq("Steve Butterworth")
    end

    it "defaults tags to an empty array and thumbnail/cover to nil when omitted" do
      beta = described_class.find("beta-post")
      expect(beta.tags).to eq([])
      expect(beta.thumbnail).to be_nil
      expect(beta.cover).to be_nil
    end

    it "computes reading time as max(1, word count / 200) minutes, as an Integer" do
      expect(described_class.find("alpha-post").reading_time).to eq(1) # 203 words
      expect(described_class.find("beta-post").reading_time).to eq(2)  # 450 words
      expect(described_class.find("gamma-post").reading_time).to eq(1) # 8 words, floored to the minimum
      expect(described_class.find("alpha-post").reading_time).to be_a(Integer)
    end
  end
end
