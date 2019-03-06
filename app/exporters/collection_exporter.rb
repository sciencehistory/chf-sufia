class CollectionExporter < Exporter
  def edit_hash(h)
    h['members'] = members
    h
  end

  def members()
    target_item.member_ids.compact
  end

  def self.exportee()
    return Collection
  end
end
