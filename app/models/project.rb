# A portfolio project loaded from content/projects/<slug>.md. No database.
class Project
  def self.content_dir
    Rails.root.join("content/projects")
  end

  def self.all
    Dir.glob(content_dir.join("*.md"))
       .reject { |p| File.basename(p).start_with?("_") }
       .map { |p| new(Pathname.new(p)) }
       .sort_by { |proj| [ proj.order, -proj.year ] }
  end

  def self.find(slug)
    path = content_dir.join("#{slug}.md")
    return nil unless path.file?

    new(path)
  end

  def initialize(path)
    @file = ContentFile.new(path)
    @slug = path.basename(".md").to_s
  end

  attr_reader :slug

  def title = data["title"]
  def role = data["role"]
  def brand = data["brand"]
  def delivered_via = data["delivered_via"]
  def year = (data["year"] || 0).to_i
  def period = data["period"]
  def order = (data["order"] || 999).to_i
  def tech = Array(data["tech"])
  def cover = data["cover"]
  def gallery = Array(data["gallery"])
  def videos = Array(data["videos"] || data["video"]).reject { |v| v.to_s.strip.empty? }
  def quote = data["quote"]
  def quote_author = data["quote_author"]
  def body_html = @file.body_html

  def lightbox?
    gallery.any? || videos.any?
  end

  def credit
    return nil if brand.blank?
    return "Delivered for #{brand}" if delivered_via.blank?

    "Delivered for #{brand} via #{delivered_via}"
  end

  private

  def data = @file.data
end
