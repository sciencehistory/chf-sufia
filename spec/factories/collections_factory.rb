# import collection_factory from sufia into local app
load Sufia::Engine.root.join("spec/factories/collections_factory.rb").to_s

FactoryGirl.modify do
  factory(:collection) do
    trait :with_image do
      representative_image_path "1831ck36t_2x.jpg"
    end
  end
end
