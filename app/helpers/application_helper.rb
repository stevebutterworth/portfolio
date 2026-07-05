module ApplicationHelper
  # Media lives in public/media and is referenced by its path after public/media/.
  def asset_media(path)
    "/media/#{path}"
  end
end
