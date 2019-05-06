module DescriptionFormatterHelper

  def format_description(text, truncate: false)
    # sanitize. should have been sanitized on input, but just to
    # be safe.
    text = DescriptionSanitizer.new(add_target_blank: true).sanitize(text).html_safe

    # truncate, may contain HTML
    if truncate
      text = HtmlAwareTruncation.truncate_html(text, length: 220, separator: /\s/)
    end

    # And convert line breaks to paragraphs. Don't need to sanitize, we
    # already did.
    text = simple_format(text, {}, sanitize: false)

    # Extracted from sufia helper `text = iconify_auto_link(text), a sufia helper to turn URLs
    # into links. But we want to turn off sanitization, cause we're already sanitizing how we
    # want previously. `auto_link` comes from `rails_autolink` gem, and it's possible we don't
    # really need it in our chf_sufia app at all we just inherited it from sufia, but we'll
    # leave it for now.
    text= auto_link(text, sanitize: false) do |value|
        "<span class='glyphicon glyphicon-new-window'></span>#{('&nbsp;' + value) if show_link}"
    end.html_safe

    text
  end


  def format_description_for_index(field)
    if field.is_a? Hash
      text = field[:value].join("\n\n")
    else
      text = field
    end

    format_description(text, truncate: true)
  end


end
