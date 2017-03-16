module DescriptionFormatterHelper

  def format_description(text, truncate: false)
    # sanitize. should have been sanitized on input, but just to
    # be safe.
    text = DescriptionSanitizer.new.sanitize(text).html_safe

    # truncate, make sure to tell it not to escape again, we already have.
    # TODO: This is not a good solution for HTML text, may truncate in the middle
    # of a tag, have to fix.
    text = truncate(text, escape: false, length: 400, separator: /\s/)

    # And convert line breaks to paragraphs
    text = simple_format(text)

    # a sufia helper to turn URLs into links.
    text = iconify_auto_link(text)

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
