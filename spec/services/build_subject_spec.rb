require 'spec_helper'

describe 'Service::AlertsBuilder' do
  context 'with one tracker' do
    let(:user) { FactoryGirl.create(:user) }
    let(:list)          { FactoryGirl.create(:list) }
    let(:notification)  { 'email' }
    let(:options)       do
      {
        'alert_id' => alert.id,
        'uuid' => '8c96cfdc-3af0-4e2b-9bc8-704e8b005892',
        'notification' => notification,
        'client_data' => JSON.parse(File.read('./spec/fixtures/client_data.json'))['data']
      }
    end
    let(:alert) { FactoryGirl.create(:alert_with_trackers, :product_availability_alert, { user: user, trackers_count: 1 }) }
    let(:product) { JSON.parse(File.read('./spec/fixtures/product_availability_alert}.json')) }

    subject { Service::AlertsBuilder.new(options) }

    describe '.build_subject' do
      [
        {
          'clients' => ['xyz'],
          'template' => 'abc',
          'subject' => 'Acme Two has been updated'
        },
        {
          'clients' => ['xyz'],
          'template' => 'recommendations',
          'subject' => 'Alert regarding Acme Two'
        },
        {
          'clients' => ['wldemo', 'client1ace', 'client1acedev', 'client1atv', 'client1atvdev', 'client1grl', 'client1grldev', 'client1indian', 'client1indiandev', 'client1ranger', 'client1rangerdev', 'client1rzr', 'client1rzrdev', 'client1', 'client1dev', 'client1victory', 'client1victorydev'],
          'template' => 'now_tracking',
          'subject' => 'You are now tracking this product!'
        },
        {
          'clients' => ['wldemo', 'client1ace', 'client1acedev', 'client1atv', 'client1atvdev', 'client1grl', 'client1grldev', 'client1indian', 'client1indiandev', 'client1ranger', 'client1rangerdev', 'client1rzr', 'client1rzrdev', 'client1', 'client1dev', 'client1victory', 'client1victorydev'],
          'template' => 'abc',
          'subject' => 'Back In Stock Alert: Acme Two'
        },
        {
          'clients' => ['client4', 'client4dev'],
          'template' => 'now_tracking',
          'subject' => "You're signed up for Availability Alerts. We'll let you know . . ."
        },
        {
          'clients' => ['client4', 'client4dev'],
          'template' => 'abc',
          'subject' => 'Acme Two is back in stock'
        },
        {
          'clients' => ['client2', 'client2dev'],
          'template' => 'now_tracking',
          'subject' => 'Sign up Confirmation - In Stock Alerts'
        },
        {
          'clients' => ['client2', 'client2dev'],
          'template' => 'abc',
          'subject' => 'Back In Stock Alert! - Acme Two'
        },
        {
          'clients' => ['lastcall'],
          'template' => 'abc',
          'subject' => 'New Arrivals from Your Favorite Designers'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'abc',
          'subject' => 'Product Alert! Acme Two'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_price_change',
          'subject' => 'Price Drop Alert! Acme Two'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_availability',
          'subject' => 'Back In Stock Alert! Acme Two'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_preorder',
          'subject' => 'Pre-Order Alert! Acme Two'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_search_list_update',
          'subject' => 'New Products Alert! Acme Two'
        }
      ].each do |context|
        context['clients'].each do |client|
          describe "#{client} #{context['template']}" do
            it "should have subject '#{context['subject']}'" do
              item = alert.trackers.first.item
              actual = subject.send(:build_subject, { template: context['template'], client: client, item: item })
              expect(actual).to eql(context['subject'])
            end
          end
        end
      end
    end

    it 'should survive missing item' do
      actual = subject.send(:build_subject, { template: 'product_preorder', client: 'wldemo' })
      expect(actual).to eql('Back In Stock Alert: ')
    end
  end

  context 'with two trackers' do
    let(:user) { FactoryGirl.create(:user) }
    let(:list)          { FactoryGirl.create(:list) }
    let(:notification)  { 'email' }
    let(:options)       do
      {
        'alert_id' => alert.id,
        'uuid' => '8c96cfdc-3af0-4e2b-9bc8-704e8b005892',
        'notification' => notification,
        'client_data' => JSON.parse(File.read('./spec/fixtures/client_data.json'))['data']
      }
    end
    let(:alert) { FactoryGirl.create(:alert_with_trackers, :product_availability_alert, { user: user, trackers_count: 2 }) }
    let(:product) { JSON.parse(File.read('./spec/fixtures/product_availability_alert}.json')) }

    subject { Service::AlertsBuilder.new(options) }

    describe '.build_subject' do
      [
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'abc',
          'subject' => 'Fried Chicken Alert'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_price_change',
          'subject' => 'Fried Chicken Alert'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_availability',
          'subject' => 'Fried Chicken Alert'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_preorder',
          'subject' => 'Fried Chicken Alert'
        },
        {
          'clients' => ['client3', 'client3dev'],
          'template' => 'product_search_list_update',
          'subject' => 'Fried Chicken Alert'
        }
      ].each do |context|
        context['clients'].each do |client|
          describe "#{client} #{context['template']}" do
            it "should have subject '#{context['subject']}'" do
              item = alert.trackers.first.item
              actual = subject.send(:build_subject, { template: context['template'], client: client, item: item, item_count: 2 })
              expect(actual).to eql(context['subject'])
            end
          end
        end
      end
    end
  end
end
