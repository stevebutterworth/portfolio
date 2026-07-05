# Reads a content file split into optional YAML front-matter and a markdown body.
# Rendering is memoised in the Rails cache keyed by path + mtime, so files are
# only re-parsed when they change.
class ContentFile
  FRONT_MATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m

  def initialize(path)
    @path = Pathname.new(path)
  end

  attr_reader :path

  def exists?
    path.file?
  end

  def data
    parsed[:data]
  end

  def body_markdown
    parsed[:body]
  end

  def body_html
    Rails.cache.fetch(cache_key) { Commonmarker.to_html(body_markdown) }
  end

  private

  def parsed
    @parsed ||= begin
      raw = path.read
      if (m = raw.match(FRONT_MATTER))
        { data: YAML.safe_load(m[:yaml], permitted_classes: [ Date ]) || {}, body: m[:body] }
      else
        { data: {}, body: raw }
      end
    end
  end

  def cache_key
    [ "content_html", path.to_s, path.mtime.to_i ].join("/")
  end
end
