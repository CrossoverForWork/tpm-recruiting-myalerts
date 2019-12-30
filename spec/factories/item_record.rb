require 'factory_girl'

FactoryGirl.define do
  to_create(&:save)
  sequence(:digest) { |n| "DIGEST#{n}" }

  factory :item_record, { class: Service::ItemRecord } do
    digest
    created_at { Time.now }
  end

  trait :removed_entry do
    data do
      {
        'status' => 'success',
        'data' => {
          'entries' => {
            'some_url' => {
              'status' => 'removed'
            }
          },
          'title' => 'Acme One'
        }
      }
    end
  end

  trait :present_entry do
    data do
      {
        'status' => 'success',
        'data' => {
          'entries' => {
            'some_url' => {
              'status' => 'present'
            }
          },
          'title' => 'Acme Two'
        }
      }
    end
  end

  trait :composite_prev do
    data do
      {
        'status' => 'success',
        'data' => {
          'urls' => [
            {
              'url' => 'some_url',
              'price' => 1_000,
              'out-of-stock' => true
            }
          ],
          'title' => 'Acme Three'
        }
      }
    end
  end

  trait :composite_curr do
    data do
      {
        'status' => 'success',
        'data' => {
          'urls' =>
           [
             {
               'url' => 'some_url',
               'price' => 100,
               'out-of-stock' => false
             }
           ],
          'title' => 'Acme Four'
        }
      }
    end
  end

  trait :registry_prev do
    data do
      {
        'status' => 'success',
        'data' => {
          'entries' => {
            'some_url' => {
              'status' => 'removed',
              'available' => 0,
              'price' => 1_000,
              'purchased' => '3'
            }
          },
          'title' => 'Acme Five'
        }
      }
    end
  end

  trait :registry_curr do
    data do
      {
        'status' => 'success',
        'data' => {
          'entries' => {
            'some_url' => {
              'status' => 'present',
              'available' => 1,
              'price' => 100,
              'purchased' => '5',
              'requested' => '10'
            }
          },
          'title' => 'Acme Six'
        }
      }
    end
  end

  trait :product_100 do
    data do
      {
        'status' => 'success',
        'type' => 'product',
        'data' => {
          'currency' => 'USD',
          'price' => '100',
          'title' => 'fancy things',
          'out-of-stock' => true,
          'sku' => '1112223',
          'upc' => '11223344556',
          'brand' => 'Acme Tires'
        }
      }
    end
  end

  trait :product_200 do
    data do
      {
        'status' => 'success',
        'type' => 'product',
        'data' => {
          'currency' => 'USD',
          'price' => '200',
          'title' => 'fancy things',
          'out-of-stock' => true,
          'sku' => '1112223',
          'upc' => '11223344556',
          'category' => 'First > Second'
        }
      }
    end
  end

  trait :product_300 do
    data do
      {
        'status' => 'success',
        'type' => 'product',
        'data' => {
          'currency' => 'USD',
          'price' => '300',
          'title' => 'fancy things',
          'out-of-stock' => false,
          'sku' => '1112223',
          'upc' => '11223344556',
          'color' => 'Puce'
        }
      }
    end
  end
end
