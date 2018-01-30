module CHF
  # This was intended to be the start of a re-usble RIS-export module, but RIS
  # ends up more complicated than anticiapted, different field names mean different
  # things depending on TY citation type. Here's how zotero thinks some legacy
  # software did it at some point: https://github.com/aurimasv/translators/wiki/RIS-Tag-Map-(narrow)
  # So this API may or may not be powerful enough.
  #
  # But you make a sub-class, then in the subclass can configure a `get_type`
  # lambda, as well as make multiple `serialize` statements to establish mappings.
  # See our local CHF::RisSerializer sub-class.
  class RisSerializerBase
    LINE_END = "\r\n"
    END_RECORD = "ER -#{LINE_END}"

    class_attribute :serialize_definitions
    self.serialize_definitions = []

    class_attribute :get_type
    self.get_type = proc {|model, serializer| nil }

    class_attribute :default_type
    # some sources suggest manuscript rather than generic is best default type for archival content
    self.default_type = "MANSCPT"

    class_attribute :default_multiple
    self.default_multiple = Set.new(%w{AU L1 L2 LK KW UR N1})


    # class-level 'macro' to define serialization of properties in sub-classes
    def self.serialize(ris_tag, property: nil, predicate: nil, multiple: nil, &block)
      ris_tag = ris_tag.to_s.upcase
      multiple ||= multiple.nil? ? default_multiple.include?(ris_tag) : multiple

      unless property.present? || predicate.present? || block_given?
        raise ArgumentError, "require either 'property' or 'predicate' argument, or a block"
      end

      self.serialize_definitions << SerializeDefinition.new(
        ris_tag: ris_tag,
        model_property: property,
        model_predicate: predicate.to_s,
        multiple: multiple,
        block: block
      )
    end

    def self.ris_date(year:, month: nil, day: nil, extra: nil)
      str = year.to_s

      str += "/"
      if month.present?
        str += "%02i" % month.to_i
      end

      str += "/"
      if day.present?
        str += "%02i" % day.to_i
      else

      end

      str += "/"
      if extra.present?
        str += extra
      end

      str
    end

    attr_reader :model

    def initialize(model)
      @model = model
    end

    def serialize
      lines = []
      lines << "TY  - #{get_type.call(model, self) || default_type}"

      serialize_definitions.each do |serialize_defn|
        lines.concat serialize_defn.lines(model)
      end

      lines << END_RECORD
      return lines.join(LINE_END)
    end
    alias_method :to_ris, :serialize

    protected


    class SerializeDefinition < Struct.new(:ris_tag, :model_property, :model_predicate, :multiple, :block)
      def initialize(args = {})
        args.each_pair do |key, value|
          send("#{key}=", value)
        end
      end

      def lines(model)
        extract(model).collect do |value|
          "#{ris_tag.to_s.upcase}  - #{value}"
        end
      end

      def extract(model)
        values = []

        # first property(ies)
        if model_property.present?
          Array(model_property).each do |property|
            byebug if property.to_s =~ /\:/
            values.concat Array(model.send(property))

            break if values.present? && !multiple
          end
        end

        if (values.empty? || !multiple) && model_predicate.present?

        end

        if (values.empty? || !multiple) && block.present?
          values.concat Array(block.call(model))
        end

        unless multiple
          values = values.slice!(0, 1)
        end

        values.collect(&:presence).compact

        return values
      end

    end
  end
end
