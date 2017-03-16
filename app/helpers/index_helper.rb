module IndexHelper
  def format_description_for_index(field)
    if field.is_a? Hash
      text = field[:value].join("\n\n")
    else
      text = field
    end

    iconify_auto_link(text)
  end
end
