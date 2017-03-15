class ChfIndexPresenter < Blacklight::IndexPresenter
  class_attribute :description_max_chars
  self.description_max_chars = 400

  attr_reader :description_field

  def initialize(*args)
    super
    # This is an attempt to not hard-code in that our field is called
    # `description_tesim`, so that doesn't break if it's changed, we
    # just look for the "description" field. Not really sure if this is
    # really less fragile, or if there was a better place to get this.
    @description_field = configuration.index_fields.values.
      find { |conf| conf.itemprop == "description" }.
      field
  end

  def field_value(field, *other_args)
    case field
    when description_field
      view_context.truncate(super, length: description_max_chars, separator: /\s/)
    else
      super
    end
  end
end
