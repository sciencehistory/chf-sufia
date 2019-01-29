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
    result
  end

  def post_clean(hash)
    hash.select { |key, value| value!=[] && value != nil }
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
    #begin
      JSON.pretty_generate(to_hash())
    #rescue
    #  byebug
    #end
  end

  def dir()
    Rails.root.join('tmp', 'export', self.class.dirname())
  end

  def write_to_file()
    puts ("writing #{filename}")
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