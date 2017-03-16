module IndexHelper
  def format_description_for_index(field)
    if field.is_a? Hash
      text = field[:value].join("\n\n")
    else
      text = field
    end

    text = truncate(text, length: 400, separator: /\s/)

    # a sufia helper to turn URLs into links.
    iconify_auto_link(text)
  end
end
