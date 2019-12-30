require 'factory_girl'

FactoryGirl.define do
  factory :list, { class: Service::List } do
    name      'Default'
    slug      'default'
    meta      { {} }
    user
  end
end
