FactoryGirl.define do
  factory :generic_work, aliases: [:work], class: GenericWork do
    ignore do
      user { FactoryGirl.create(:user) }
    end

    title ['Test title']
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end
  end
end
