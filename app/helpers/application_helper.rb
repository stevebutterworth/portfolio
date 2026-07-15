module ApplicationHelper
  # Media lives in public/media and is referenced by its path after public/media/.
  def asset_media(path)
    "/media/#{path}"
  end

  # A mailto link that keeps the address out of the HTML source: the parts ship
  # in separate data attributes and the mailto Stimulus controller assembles the
  # real href (and label, when no block content is given) in the browser.
  # Without JavaScript the link text falls back to "user [at] domain".
  def obfuscated_mail_to(email, html_options = {}, &block)
    user, domain = email.split("@", 2)
    data = { controller: "mailto", mailto_user_value: user, mailto_domain_value: domain }
    if block
      content_tag(:a, capture(&block), html_options.merge(href: "#", data: data))
    else
      content_tag(:a, "#{user} [at] #{domain}", html_options.merge(href: "#", data: data.merge(mailto_label_value: true)))
    end
  end
end
