# Generated by curation_concerns:models:install
class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior
  include Sufia::FileSetBehavior

  def create_derivatives(filename)
    super
    # create a preview derivative for image assets
    if self.class.image_mime_types.include? mime_type
      Hydra::Derivatives::ImageDerivatives.create(filename,
                                                  outputs: [{ label: :preview, format: 'jpg', size: '1000x750>', url: derivative_url('jpeg') }])
    end
  end

end