# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :qa_local_authority, :class => 'Qa::LocalAuthority' do
    name "MyString"
  end
end
