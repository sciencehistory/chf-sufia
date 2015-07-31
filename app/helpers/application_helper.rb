module ApplicationHelper
  require_dependency Rails.root.join('lib','chf','utils','parse_fields')

  # turn something like "b9879|f9876655|v65464|p24" into
  #   something like "Box 9879, Folder 9876655, Volume 65464, Part 24"
  def display_physical_container(str)
    pc_hash = CHF::Utils::ParseFields.parse_physical_container str
    display = pc_hash.map { |k,v| [CHF::Utils::ParseFields.physical_container_fields[k].capitalize, v].flatten.join(' ') }.flatten.join(', ')
  end

end
