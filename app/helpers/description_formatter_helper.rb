module DescriptionFormatterHelper

  def format_description(text, truncate: false)
    # sanitize. should have been sanitized on input, but just to
    # be safe.
    text = DescriptionSanitizer.new.sanitize(text).html_safe

    # truncate, may contain HTML
    if truncate
      text = HtmlAwareTruncation.truncate_html(text, length: 220, separator: /\s/)
    end

    # And convert line breaks to paragraphs
    text = simple_format(text)

    # a sufia helper to turn URLs into links.
    text = iconify_auto_link(text)

    text = add_target_blank(text)

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


  def add_target_blank(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.css('a').each do |link|
      link['target'] = '_blank'
    end
    doc.to_s.html_safe
  end


end
