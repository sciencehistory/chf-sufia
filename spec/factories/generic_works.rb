FactoryGirl.define do
  factory :generic_work, aliases: [:work, :public_work], class: GenericWork do
    transient do
      user { FactoryGirl.create(:user) }
    end

    title ['Test title']
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    factory :private_work, aliases: [:public_file] do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    trait :with_complete_metadata do
      title         ['titletitle']
      language      ['languagelanguage']
      creator       ['creatorcreator']
      contributor   ['contributorcontributor']
      publisher     ['publisherpublisher']
      subject       ['subjectsubject']
      resource_type ['resource_typeresource_type']
      description   ['descriptiondescription']
      related_url   ['http://example.org/TheRelatedURLLink/']
      rights        ['http://creativecommons.org/licenses/by/3.0/us/']
    end

  end
end
