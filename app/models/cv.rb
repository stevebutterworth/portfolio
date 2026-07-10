# Steve Butterworth's CV, loaded from content/cv.yml. No database.
class Cv
  def self.content_path
    Rails.root.join("content/cv.yml")
  end

  def self.load
    new(YAML.safe_load_file(content_path, permitted_classes: [], aliases: false))
  end

  def initialize(data)
    @data = data
  end

  def name = data["name"]
  def title = data["title"]
  def tagline = data["tagline"]
  def location = data["location"]
  def email = data["email"]
  def linkedin = data["linkedin"]
  def github = data["github"]
  def education = data["education"]
  def profile = data["profile"]
  def profile_paragraphs = profile.to_s.split("\n").map(&:strip).reject(&:empty?)
  def skills = data["skills"] || {}
  def jobs = data["jobs"] || []
  def additional = data["additional"] || []

  def to_markdown
    [
      header_markdown,
      section("Profile", profile_paragraphs.join("\n\n")),
      section("Core skills", skills_markdown),
      experience_markdown,
      additional_markdown
    ].join("\n\n")
  end

  private

  attr_reader :data

  def header_markdown
    contact = [ location, email, linkedin, github ].compact.join(" · ")
    [ "# #{name}", title, contact ].join("\n")
  end

  def skills_markdown
    skills.map { |category, values| "- **#{category}:** #{values}" }.join("\n")
  end

  def experience_markdown
    section("Experience", jobs.map { |job| job_markdown(job) }.join("\n\n"))
  end

  def additional_markdown
    section("Additional experience", additional.map { |job| job_markdown(job) }.join("\n\n"))
  end

  def job_markdown(job, level: 3)
    parts = [ "#{"#" * level} #{job["role"]}, #{job["org"]} (#{job["when"]})" ]
    parts << job["context"] if job["context"].present?
    parts << Array(job["bullets"]).map { |bullet| "- #{bullet}" }.join("\n")
    engagements = Array(job["engagements"])
    parts << engagements.map { |engagement| job_markdown(engagement, level: level + 1) }.join("\n\n") if engagements.any?
    parts.join("\n\n")
  end

  def section(title, body)
    "## #{title}\n\n#{body}"
  end
end
