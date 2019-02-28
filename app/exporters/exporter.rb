require "json"

class Exporter
  attr_reader :target_item

  def initialize(target_item, options = {})
    raise ArgumentError unless target_item.is_a? self.class.exportee
    @target_item = target_item
  end

  def pre_clean()
    result = target_item.attributes
    result.each do |k, v|
      result[k] = v.to_a if v.is_a? ActiveTriples::Relation
    end
    # These are useless to us, so let's not print them out:
    result.reject! { |k, v| (v.is_a? Array) &&  (v.first.is_a? ActiveTriples::Resource) }
    result
  end

  def post_clean(the_hash)
    the_hash['date_uploaded'] =  the_hash['date_uploaded'].utc.to_s if the_hash['date_uploaded']
    the_hash.select { |key, value| value!=[] && value != nil }
  end

  def to_hash()
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


end
