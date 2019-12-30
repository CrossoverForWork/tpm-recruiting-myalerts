require 'factory_girl'

FactoryGirl.define do
  to_create(&:save)

  factory :alert, { class: Service::Alert } do
    transient do
      trackers []
      matches []
      items []
    end

    template 'template_1'
    match_types { matches.map(&:name) }
    user
    type 'immediate'

    data do
      {
        'alert_type' => 'immediate',
        'match_types' => matches.map(&:name),
        'matches_ids' => matches.map(&:id),
        'trackers_ids' => trackers.map(&:id),
        'items' => {
          '123' => {
            'item_id' => items[0].id,
            'matches' => {
              'now_tracking' => {}
            },
            'item_url' => items[0].url,
            'item_current_record' => {
              'data' => {
                'type' => items[0].type
              }
            }
          }
        }
      }
    end

    factory :alert_with_trackers do
      transient do
        trackers_count 5
        trackers_items []
      end

      after(:create) do |alert, evaluator|
        evaluator.trackers_count.times do |i|
          item = if i < evaluator.trackers_items.length
                   evaluator.trackers_items[i]
                 else
                   FactoryGirl.create(:item)
                 end
          curr_record = FactoryGirl.create(:item_record, :present_entry, { item_id: item.id })
          FactoryGirl.create(:item_record, :removed_entry, { item_id: item.id, created_at: curr_record.created_at - 1_000 })
          alert.add_tracker(FactoryGirl.create(:tracker, :trigger_product_availability, { item: item }))
        end
        alert.save
      end
    end
  end

  trait :product_availability_alert do
    data { JSON.parse(File.read('./spec/fixtures/product_availability_alert.json', { external_encoding: 'iso-8859-1' })) }
  end

  trait :price_drop do
    type 'immediate'
    template 'price_drop'
  end
end
