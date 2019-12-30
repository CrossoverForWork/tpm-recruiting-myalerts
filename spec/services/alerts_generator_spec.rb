require 'spec_helper'

describe Service::AlertsGenerator do
  let(:user)            { FactoryGirl.create(:user) }
  let(:list)            { FactoryGirl.create(:list) }
  let(:prev_record)     { FactoryGirl.create(:item_record, :removed_entry, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
  let(:curr_record)     { FactoryGirl.create(:item_record, :present_entry, { item_id: item.id }) }
  let(:item)            { FactoryGirl.create(:item, :job_search) }
  let(:requested_data)  { ['matches'] }
  let(:options)         do
    {
      'client_identifier' => 'wldemo',
      'user_id' => user.id,
      'trackers_ids' => [tracker.id],
      'requested_type' => alert_type,
      'requested_data' => requested_data
    }
  end
  let(:client_data) { JSON.parse(File.read('./spec/fixtures/client_data.json')) }

  before do
    allow_any_instance_of(::Service::ClientReader).to receive(:call) { client_data }
    curr_record # HACK
    prev_record # HACK
    match # HACK
  end

  shared_examples_for 'an alert generator' do |match_type|
    context 'with alert type #{match_type}' do
      let(:tracker)     { FactoryGirl.create(:tracker, { item: item, list: list }) }
      let(:match)       { FactoryGirl.create(:match, match_type, { tracker: tracker, user: user }) }
      # registry_list_update is set up as a non alertable match
      # in the fixtures
      it 'returns a success message and 1 items sent if non alertable' do
        if !match_type == :registry_list_update
          expect(subject.call).to eql({
            'status' => 'success',
            'data' => { 'sent' => 1 },
            'message' => 'processed'
          })
        end
      end

      it 'returns a success message and 0 items sent if non alertable' do
        if !match_type == :registry_list_update
          expect(subject.call).to eql({
            'status' => 'success',
            'data' => { 'sent' => 0 },
            'message' => 'processed'
          })
        end
      end

      it 'saves an alert record if alertable' do
        if !match_type == :registry_list_update
          expect { subject.call }.to change { Service::Alert.all.size }.by(1)
        end
      end

      it 'does not save an alert record if not alertable' do
        if match_type == :registry_list_update
          expect { subject.call }.to change { Service::Alert.all.size }.by(0)
        end
      end

      it 'does not generate an alert if alert_creating switch is off' do
        client_data['data']['switches']['alerts']['creation'] = false
        expect { subject.call }.to change { Service::Alert.all.size }.by(0)
      end

      it 'does not send and alert if dispatch_alerts switch is off' do
        if !match_type == :registry_list_update # non alertable record
          client_data['data']['switches']['alerts']['dispatch'] = false
          expect { subject.call }.to change { Service::Alert.all.size }.by(1)
        end
      end
    end
  end

  subject { Service::AlertsGenerator.new(options) }

  context 'with product type alert' do
    let(:alert_type) { 'product' }
    let(:item)        { FactoryGirl.create(:item) }
    let(:prev_record) { FactoryGirl.create(:item_record, :registry_prev, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
    let(:curr_record) { FactoryGirl.create(:item_record, :registry_curr, { item_id: item.id }) }
    it_behaves_like 'an alert generator', :product_price_change
    it_behaves_like 'an alert generator', :product_availability
  end

  context 'with product search type alert' do
    let(:alert_type) { 'product_search' }
    let(:item)        { FactoryGirl.create(:item, :product_search) }
    let(:prev_record) { FactoryGirl.create(:item_record, :registry_prev, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
    let(:curr_record) { FactoryGirl.create(:item_record, :registry_curr, { item_id: item.id }) }
    it_behaves_like 'an alert generator', :product_search_list_update
    it_behaves_like 'an alert generator', :product_search_price_change
  end

  context 'with registry type alert' do
    let(:alert_type) { 'registry' }
    let(:item)        { FactoryGirl.create(:item, :wishlist) }
    let(:prev_record) { FactoryGirl.create(:item_record, :registry_prev, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
    let(:curr_record) { FactoryGirl.create(:item_record, :registry_curr, { item_id: item.id }) }
    it_behaves_like 'an alert generator', :registry_availability
    it_behaves_like 'an alert generator', :registry_entry_update
    it_behaves_like 'an alert generator', :registry_list_update
    it_behaves_like 'an alert generator', :registry_purchase
  end

  context 'with composite product type alert' do
    let(:alert_type)  { 'composite_product' }
    let(:item)        { FactoryGirl.create(:item, :composite_product) }
    let(:prev_record) { FactoryGirl.create(:item_record, :registry_prev, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
    let(:curr_record) { FactoryGirl.create(:item_record, :registry_curr, { item_id: item.id }) }
    it_behaves_like 'an alert generator', :composite_product_availability
    it_behaves_like 'an alert generator', :composite_product_price_change
  end

  context 'with Job search type alert' do
    let(:alert_type)  { 'job_search' }
    let(:item)        { FactoryGirl.create(:item, :job_search) }
    let(:prev_record) { FactoryGirl.create(:item_record, :registry_prev, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
    let(:curr_record) { FactoryGirl.create(:item_record, :registry_curr, { item_id: item.id }) }
    it_behaves_like 'an alert generator', :job_search_list_update
  end

  context 'with single notification type' do
    let(:alert_type)  { 'product' }
    let(:match_name)  { 'product_price_change' }
    let(:item)        { FactoryGirl.create(:item) }
    let(:prev_record) { FactoryGirl.create(:item_record, :registry_prev, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
    let(:curr_record) { FactoryGirl.create(:item_record, :registry_curr, { item_id: item.id }) }
    let(:tracker)     { FactoryGirl.create(:tracker, { item: item, list: list }) }
    let(:match)       { FactoryGirl.create(:match, :product_price_change, { tracker: tracker, user: user }) }

    it 'returns a success message and 1 items sent' do
      sender = instance_double('AlertSender', { call: {
        'status' => 'success'
      } })

      allow(Service::AlertSender).to receive(:build) { sender }
      expect(Service::AlertSender).to receive(:build).with(hash_including({ 'notification' => 'email' })).once

      expect(subject.call).to eql({
        'status' => 'success',
        'data' => {
          'sent' => 1
        },
        'message' => 'processed'
      })
    end

    it 'does create an email alert record' do
      expect { subject.call }.to change { Service::Alert.all.size }.by(1)
    end

    it 'does not create an alert if alert_creating switch is off' do
      client_data['data']['switches']['alerts']['creation'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(0)
    end

    it 'does create an alert if dispatch_alerts switch is off' do
      client_data['data']['switches']['alerts']['dispatch'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(1)
    end
  end

  context 'with multiple notification types' do
    let(:alert_type)  { 'product' }
    let(:match_name)  { 'product_price_change' }
    let(:item)        { FactoryGirl.create(:item) }
    let(:prev_record) { FactoryGirl.create(:item_record, :registry_prev, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
    let(:curr_record) { FactoryGirl.create(:item_record, :registry_curr, { item_id: item.id }) }
    let(:tracker)     { FactoryGirl.create(:tracker, :notification_email_sms, { item: item, list: list }) }
    let(:match)       { FactoryGirl.create(:match, :product_price_change, { tracker: tracker, user: user }) }
    let(:sender)      { instance_double('AlertSender', { call: { 'status' => 'success' } }) }

    before(:each) do
      allow(Service::AlertSender).to receive(:build) { sender }
    end

    it 'returns a success message and 2 items sent' do
      expect(Service::AlertSender).to receive(:build).with(hash_including({ 'notification' => 'email' })).once
      expect(Service::AlertSender).to receive(:build).with(hash_including({ 'notification' => 'sms' })).once

      expect(subject.call).to eql({
        'status' => 'success',
        'data' => {
          'sent' => 2
        },
        'message' => 'processed'
      })
    end

    it 'does create an sms alert record' do
      expect { subject.call }.to change { Service::Alert.all.size }.by(2)
    end

    it 'does not create an alert if alert_creating switch is off' do
      client_data['data']['switches']['alerts']['creation'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(0)
    end

    it 'does create an alert if dispatch_alerts switch is off' do
      client_data['data']['switches']['alerts']['dispatch'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(2)
    end
  end
end
