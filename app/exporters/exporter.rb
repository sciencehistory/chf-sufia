require "json"
class Exporter
  attr_reader :target_item

  def initialize(target_item, options = {})
    raise ArgumentError unless target_item.is_a? self.class.exportee
    @target_item = target_item
  end

  def pre_clean()
    result = target_item.attributes

    # For collections, we need to get this metadata from Fedora.
    if target_item.is_a? Collection
      date_uploaded_predicate = 'http://fedora.info/definitions/v4/repository#created'
      date_modified_predicate = 'http://fedora.info/definitions/v4/repository#lastModified'
      raw_date_uploaded = target_item.resource.to_a.
        select { |x| x.predicate.to_s == date_uploaded_predicate }.
        first.object.to_s
      raw_date_modified = target_item.resource.to_a.
        select { |x| x.predicate.to_s == date_modified_predicate }.
        first.object.to_s
    else
        raw_date_uploaded = target_item.date_uploaded
        raw_date_modified = target_item.date_modified
    end

    result['date_uploaded'] = date_export_format(raw_date_uploaded)
    result['date_modified'] = date_export_format(raw_date_modified)

    result.each do |k, v|
      result[k] = v.to_a if v.is_a? ActiveTriples::Relation
    end

    result ['access_control'] = access_control
    # These are useless to us, so let's not print them out:
    result.reject! { |k, v| (v.is_a? Array) &&  (v.first.is_a? ActiveTriples::Resource) }
    result
  end

  def date_export_format(date)
    return if date.nil?
    return date.utc.to_s if date.is_a? DateTime
    return DateTime.parse(date).utc.to_s if date.is_a? String
    return
  end

  def post_clean(the_hash)
    the_hash.select { |key, value| value!=[] && value != nil }
  end

  def my_count(x)
    x.sum { |x| 1 }
  end

  def to_hash()
    my_count(GenericWork.find(target_item.id).additional_credit) # 2
    my_count(target_item.additional_credit) # 4
    result = pre_clean()
    result = edit_hash(result)
    result = post_clean(result)
    result
  end

  # subclass this to edit the hash that gets converted to json...
  def edit_hash(h)
    return h
  end

  def to_json()
    JSON.fast_generate(to_hash())
  end

  def dir()
    Rails.root.join('tmp', 'export', self.class.dirname())
  end

  def write_to_file()
    File.open("#{dir}/#{filename}.json", 'w') { |file| file.write(to_json()) }
  end

  def filename()
    target_item.id
  end

  def self.dirname()
    "#{self.exportee.name.downcase}s"
  end

  def self.exportee()
    raise NotImplementedError
  end

  def access_control()
    return 'private' if @target_item.access_control.nil?
    @target_item.access_control.contains.each do |ac|
      if ac.agent.first.id.include?('public') && ac.mode.first.id.include?('Read')
        return 'public'
      end
    end
    'private'
  end

end
