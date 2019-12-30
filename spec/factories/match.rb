require 'factory_girl'

FactoryGirl.define do
  to_create(&:save)
  factory :match, { class: Service::Match } do
    tracker
    user
  end

  trait :product_availability do
    name 'product_availability'
    data { JSON.parse(File.read('./spec/fixtures/match_data/product_availability.json')) }
  end

  trait :product_price_change do
    name 'product_price_change'
    data { JSON.parse(File.read('./spec/fixtures/match_data/price_change.json')) }
  end

  trait :product_price_change_other do
    name 'product_price_change'
    data { JSON.parse(File.read('./spec/fixtures/match_data/price_change_other.json')) }
  end

  trait :product_search_list_update do
    name 'product_price_change'
    data { JSON.parse(File.read('./spec/fixtures/match_data/product_search_list_update.json')) }
  end

  trait :product_search_price_change do
    name 'product_price_change'
    data { JSON.parse(File.read('./spec/fixtures/match_data/product_search_price_change.json')) }
  end

  trait :registry_availability do
    name 'registry_availability'
    data { JSON.parse(File.read('./spec/fixtures/match_data/registry_availability.json')) }
  end

  trait :registry_entry_update do
    name 'registry_entry_update'
    data { JSON.parse(File.read('./spec/fixtures/match_data/registry_entry_update.json')) }
  end

  trait :registry_list_update do
    name 'registry_list_update'
    data { JSON.parse(File.read('./spec/fixtures/match_data/registry_list_update.json')) }
  end

  trait :registry_few_items_remaining do
    name 'registry_few_items_remaining'
    data { JSON.parse(File.read('./spec/fixtures/match_data/registry_few_items_remaining.json')) }
  end

  trait :registry_price_change do
    name 'registry_price_change'
    data { JSON.parse(File.read('./spec/fixtures/match_data/registry_price_change.json')) }
  end

  trait :registry_purchase do
    name 'registry_purchase'
    data { JSON.parse(File.read('./spec/fixtures/match_data/registry_purchase.json')) }
  end

  trait :composite_product_availability do
    name 'composite_product_availability'
    # Use correct JSON
    data { JSON.parse(File.read('./spec/fixtures/match_data/composite_product_availability.json')) }
  end

  trait :composite_product_price_change do
    name 'composite_product_price_change'
    data { JSON.parse(File.read('./spec/fixtures/match_data/composite_product_price_change.json')) }
  end

  trait :job_search_list_update do
    name 'job_search_list_update'
    data { JSON.parse(File.read('./spec/fixtures/match_data/job_search_list_update.json', { external_encoding: 'iso-8859-1' })) }
  end
end
