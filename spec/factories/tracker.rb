require 'factory_girl'

FactoryGirl.define do
  to_create(&:save)
  factory :tracker, { class: Service::Tracker } do
    notification_methods  { ['email'] }
    meta                  { {} }
    triggers              [{ 'name' => 'registry_availability', 'options' => {} }]
    list
    item
  end

  trait :trigger_job_search_list_update do
    triggers [{ 'name' => 'job_search_list_update', 'options' => { 'detectable' => ['entry_added', 'entry_removed'] } }]
  end

  trait :trigger_composite_product_availability do
    triggers [{ 'name' => 'composite_product_availability', 'options' => {} }]
  end

  trait :trigger_composite_product_price_change do
    triggers [{ 'name' => 'composite_product_price_change', 'options' => { 'conditions' => [{ 'name' => 'price_drop' }] } }]
  end

  trait :trigger_registry_availability do
    triggers [{ 'name' => 'registry_availability', 'options' => {} }]
  end

  trait :trigger_registry_entry_update do
    triggers [{ 'name' => 'registry_entry_update', 'options' => {} }]
  end

  trait :trigger_registry_few_items_remaining do
    triggers [{ 'name' => 'registry_few_items_remaining', 'options' => { 'min' => 10 } }]
  end

  trait :trigger_registry_list_update do
    triggers [{ 'name' => 'registry_list_update', 'options' => { 'detectable' => ['entry_added', 'entry_removed'] } }]
  end

  trait :trigger_registry_price_change do
    triggers [{ 'name' => 'registry_price_change', 'options' => { 'conditions' => [{ 'name' => 'price_drop' }] } }]
  end

  trait :trigger_registry_purchase do
    triggers [{ 'name' => 'registry_purchase', 'options' => {} }]
  end

  trait :trigger_product_availability do
    triggers [{ 'name' => 'product_availability', 'options' => {} }]
  end

  trait :trigger_product_price_change do
    triggers [{ 'name' => 'product_price_change', 'options' => {} }]
  end

  trait :notification_email_sms do
    notification_methods { ['email', 'sms'] }
  end
end
