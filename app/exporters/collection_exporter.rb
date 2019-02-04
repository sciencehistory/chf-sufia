class CollectionExporter < Exporter
  def edit_hash(h)
    h['members'] = members
    h
  end

  def members()
    target_item.members.map(&:id)
  end

  def self.exportee()
    return Collection
  end

end
