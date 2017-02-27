class BlankTargetAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer
  private

    def li_value(value)
      auto_link(value, :html => { :target => '_blank' }) do |link|
        "<span class='glyphicon glyphicon-new-window'></span>&nbsp;#{link}"
      end
    end
end
