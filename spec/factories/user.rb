require 'factory_girl'

FactoryGirl.define do
  to_create(&:save)
  sequence(:user_identifier) { |n| "johndoe+#{n}@example.com" }
  sequence(:mongoid) { |n| "0000#{n}" }

  factory :user, { class: Service::User } do
    user_identifier
    mongoid
    client_identifier   'wldemo'
    client_api_key      '0000-1234-0000-1234'
  end
end
