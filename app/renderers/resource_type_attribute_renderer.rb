class ResourceTypeAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer

  private

    ##
    # Special treatment for resource types.  Id and term from the config file are used.
    # If Id is a valid URL, then it is used as a link.  If it is not valid, it is used as plain text.
    def attribute_value_to_html(value)
      begin
        parsed_uri = URI.parse(value)
      rescue
        nil
      end
      if parsed_uri.nil?
        ERB::Util.h(value)
      else
        authority = Qa::Authorities::Local.subauthority_for('resource_types')
        %(<a href=#{ERB::Util.h(value)} target="_blank">#{authority.find(value).fetch('term')}</a>)
      end
    end
end
