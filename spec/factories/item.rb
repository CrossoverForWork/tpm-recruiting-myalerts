require 'factory_girl'

FactoryGirl.define do
  to_create(&:save)
  sequence(:url) { |n| "https://www.someurl.com/p/#{n}" }

  factory :item, { class: Service::Item } do
    url
    mongoid { BSON::ObjectId.new }
    type 'product'
  end

  trait :wishlist do
    type 'wishlist'
  end

  trait :job_search do
    type 'job_search'
  end

  trait :composite_product do
    type 'composite_product'
  end

  trait :product_search do
    type 'product_search'
  end

  trait :registry do
    type 'registry'
  end
end
