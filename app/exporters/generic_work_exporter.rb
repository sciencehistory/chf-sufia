class GenericWorkExporter < Exporter

  def edit_hash(h)
    h['child_ids'] = child_ids
    associations.each do |label, data|
      h[label] = process_association(data)
    end
    h
  end

  def child_ids
    begin
      target_item.ordered_member_ids.compact
    rescue Ldp::Gone
      # This is a bandaid for corrupt item 3r074v259
      target_item.member_ids.compact
    end
  end

  def associations
    {
      'dates' =>  {
        :target_item_key => 'date_of_work',
        :keys => %w(start finish start_qualifier finish_qualifier note),
      },
      'inscriptions'  =>  {
        :target_item_key => 'inscription',
        :keys => %w(location text display_label),
      },
      'additional_credits'  =>  {
        :target_item_key => 'additional_credit',
        :keys => %w(role name display_label)
      }
    }
  end

  def process_association(data)
    result = []
    associations = target_item.send(data[:target_item_key])
    associations.to_a.each do |d|
      #byebug
      new_assoc = {}
      data[:keys].each do |k|
        v = d.send(k)
        new_assoc[k] = v if (v.is_a? String) and (v != "")
      end
      result << new_assoc
    end
    result
  end

  def self.exportee
    return GenericWork
  end

end
