# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :qa_local_authority_entry, :class => 'Qa::LocalAuthorityEntry' do
    local_authority nil
    label "MyString"
    uri "MyString"
  end
end
