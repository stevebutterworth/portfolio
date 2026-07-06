# A blog post loaded from content/posts/<date>-<slug>.md. No database.
class Article
  DATE_PREFIX = /\A\d{4}-\d{2}-\d{2}-/

  def self.content_dir
    Rails.root.join("content/posts")
  end

  def self.all
    paths
      .map { |p| new(Pathname.new(p)) }
      .sort_by(&:date)
      .reverse
  end

  def self.find(slug)
    path = paths.find { |p| slug_for(p) == slug }
    return nil unless path

    new(Pathname.new(path))
  end

  def self.paths
    Dir.glob(content_dir.join("*.md"))
       .reject { |p| File.basename(p).start_with?("_") }
  end

  def self.slug_for(path)
    File.basename(path, ".md").sub(DATE_PREFIX, "")
  end

  def initialize(path)
    @file = ContentFile.new(path)
    @slug = self.class.slug_for(path)
  end

  attr_reader :slug

  def title = data["title"]
  def author = data["author"] || "Steve Butterworth"
  def tags = Array(data["tags"])
  def excerpt = data["excerpt"]
  def thumbnail = data["thumbnail"]
  def cover = data["cover"]
  def body_html = @file.body_html

  def date
    raw = data["date"]
    raw.is_a?(Date) ? raw : Date.parse(raw.to_s)
  end

  def reading_time
    words = @file.body_markdown.split.size
    [ 1, words / 200 ].max
  end

  private

  def data = @file.data
end
