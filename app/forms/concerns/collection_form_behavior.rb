module CollectionFormBehavior
  extend ActiveSupport::Concern
  class_methods do
    def model_attributes(params)
      clean_params = super #hydra-editor/app/forms/hydra_editor/form.rb:54
      if params[:description]
        clean_params[:description] = Array(params[:description])
        clean_params[:description].map! do |description|
          ::DescriptionSanitizer.new.sanitize(description)
        end
      end
      clean_params
    end
  end
end