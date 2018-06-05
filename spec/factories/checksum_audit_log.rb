FactoryGirl.define do
  factory :checksum_audit_log do
    file_set_id '6682x392q'
    file_id  '6682x392q/files/5ad080bc-9479-4a00-9cfc-4d53bae6ea27'
    checked_uri  'http://127.0.0.1:8080/rest/dev/66/82/x3/92/6682x392q/files/5ad080bc-9479-4a00-9cfc-4d53bae6ea27/fcr:versions/version1'
    expected_result "urn:sha1:8557baf29574415034f41ce2cc3e65f55faf937e"
    actual_result nil
    passed true
    created_at 2.days.ago

    trait :failed do
      passed false
    end


  end
end
