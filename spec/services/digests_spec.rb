require 'spec_helper'

describe 'digest alerts' do
  context 'with multiple matches' do
    let(:user) { FactoryGirl.create(:user) }
    let(:list) { FactoryGirl.create(:list) }

    let(:alert_type)  { 'product' }
    let(:match_name)  { 'product_price_change' }

    let(:one_item)        { FactoryGirl.create(:item) }
    let(:one_prev_record) { FactoryGirl.create(:item_record, :product_200, { item_id: one_item.id, created_at: one_curr_record.created_at - 1_000 }) }
    let(:one_curr_record) { FactoryGirl.create(:item_record, :product_100, { item_id: one_item.id }) }
    let(:one_tracker)     { FactoryGirl.create(:tracker, { item: one_item, list: list }) }
    let(:one_match)       { FactoryGirl.create(:match, :product_price_change, { tracker: one_tracker, user: user }) }

    let(:two_prev_record) { FactoryGirl.create(:item_record, :product_200, { item_id: one_item.id, created_at: two_curr_record.created_at - 1_000 }) }
    let(:two_curr_record) { FactoryGirl.create(:item_record, :product_300, { item_id: one_item.id }) }
    let(:two_match)       { FactoryGirl.create(:match, :product_price_change_other, { tracker: one_tracker, user: user }) }

    let(:requested_data)  { ['matches'] }
    let(:options)         do
      {
        'client_identifier' => 'wldemo',
        'user_id' => user.id,
        'trackers_ids' => [one_tracker.id],
        'requested_type' => alert_type,
        'requested_data' => requested_data
      }
    end
    let(:client_data) { JSON.parse(File.read('./spec/fixtures/client_data.json')) }

    before do
      allow_any_instance_of(::Service::ClientReader).to receive(:call) { client_data }

      # force record creation
      one_prev_record
      one_curr_record
      one_match

      two_prev_record
      two_curr_record
      two_match
    end

    subject { Service::AlertsGenerator.new(options) }

    it 'should return a success message and 1 items sent' do
      sender = instance_double('AlertSender', { call: {
        'status' => 'success'
      } })

      allow(Service::AlertSender).to receive(:build) { sender }
      expect(Service::AlertSender).to receive(:build).once

      expect(subject.call).to eql({ 'status' => 'success',
                                    'data' => {
                                      'sent' => 1
                                    },
                                    'message' => 'processed' })
    end

    it 'should create an email alert record' do
      expect { subject.call }.to change { Service::Alert.all.size }.by(1)
    end

    it 'should create an alert with merged match data' do
      subject.call
      alert = Service::Alert.first

      expect(alert.data).to include({ 'match_types' => [one_match.name] })
      expect(alert.data['matches_ids']).to match_array([one_match.id, two_match.id])
      expect(alert.data).to include({ 'trackers_ids' => [one_tracker.id] })
      expect(alert.data).to include({ 'alert_type' => alert_type })
      expect(alert.data).to include({ 'notification_method' => 'email' })
      expect(alert.data).to include('items')

      expect(alert.data['items']).to include(one_item.id.to_s)
      item_data = alert.data['items'][one_item.id.to_s]
      expect(item_data).to include('matches')

      expect(item_data['matches']).to include(one_match.name)
      match_data = item_data['matches'][one_match.name]
      expect(match_data).to include({ 'match_id' => two_match.id })
      expect(match_data).to include('current')
      expect(match_data).to include('previous')

      match_current = match_data['current']
      match_previous = match_data['previous']
      expect(match_current).to eql(two_match.data['current'])
      expect(match_previous).to eql(two_match.data['previous'])
    end

    it 'should not create an alert if alert_creating switch is off' do
      client_data['data']['switches']['alerts']['creation'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(0)
    end

    it 'should create an alert if dispatch_alerts switch is off' do
      client_data['data']['switches']['alerts']['dispatch'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(1)
    end
  end

  context 'with multiple trackers' do
    let(:user) { FactoryGirl.create(:user) }
    let(:list) { FactoryGirl.create(:list) }

    let(:alert_type)  { 'product' }
    let(:match_name)  { 'product_price_change' }

    let(:one_item)        { FactoryGirl.create(:item) }
    let(:one_prev_record) { FactoryGirl.create(:item_record, :product_200, { item_id: one_item.id, created_at: one_curr_record.created_at - 1_000 }) }
    let(:one_curr_record) { FactoryGirl.create(:item_record, :product_100, { item_id: one_item.id }) }
    let(:one_tracker)     { FactoryGirl.create(:tracker, { item: one_item, list: list }) }
    let(:one_match)       { FactoryGirl.create(:match, :product_price_change, { tracker: one_tracker, user: user }) }

    let(:two_item)        { FactoryGirl.create(:item) }
    let(:two_prev_record) { FactoryGirl.create(:item_record, :product_200, { item_id: two_item.id, created_at: two_curr_record.created_at - 1_000 }) }
    let(:two_curr_record) { FactoryGirl.create(:item_record, :product_300, { item_id: two_item.id }) }
    let(:two_tracker)     { FactoryGirl.create(:tracker, { item: two_item, list: list }) }
    let(:two_match)       { FactoryGirl.create(:match, :product_price_change_other, { tracker: two_tracker, user: user }) }

    let(:requested_data)  { ['matches'] }
    let(:options)         do
      {
        'client_identifier' => 'wldemo',
        'user_id' => user.id,
        'trackers_ids' => [one_tracker.id, two_tracker.id],
        'requested_type' => alert_type,
        'requested_data' => requested_data
      }
    end
    let(:client_data) { JSON.parse(File.read('./spec/fixtures/client_data.json')) }

    before do
      allow_any_instance_of(::Service::ClientReader).to receive(:call) { client_data }

      # force record creation
      one_prev_record
      one_curr_record
      one_match

      two_prev_record
      two_curr_record
      two_match
    end

    subject { Service::AlertsGenerator.new(options) }

    it 'should return a success message and 1 items sent' do
      sender = instance_double('AlertSender', { call: {
        'status' => 'success'
      } })

      allow(Service::AlertSender).to receive(:build) { sender }
      expect(Service::AlertSender).to receive(:build).once

      expect(subject.call).to eql({ 'status' => 'success',
                                    'data' => {
                                      'sent' => 1
                                    },
                                    'message' => 'processed' })
    end

    it 'should create an email alert record' do
      expect { subject.call }.to change { Service::Alert.all.size }.by(1)
    end

    it 'should create an alert with merged match data' do
      subject.call
      alert = Service::Alert.first

      expect(alert.data).to include({ 'match_types' => [one_match.name, two_match.name].uniq })
      expect(alert.data).to include({ 'matches_ids' => [one_match.id, two_match.id] })
      expect(alert.data).to include({ 'trackers_ids' => [one_tracker.id, two_tracker.id] })
      expect(alert.data).to include({ 'alert_type' => alert_type })
      expect(alert.data).to include({ 'notification_method' => 'email' })
      expect(alert.data).to include('items')

      expect(alert.data['items']).to include(one_item.id.to_s)
      item_data = alert.data['items'][one_item.id.to_s]
      expect(item_data).to include('matches')

      expect(item_data['matches']).to include(one_match.name)
      match_data = item_data['matches'][one_match.name]
      expect(match_data).to include({ 'match_id' => one_match.id })
      expect(match_data).to include('current')
      expect(match_data).to include('previous')

      match_current = match_data['current']
      match_previous = match_data['previous']
      expect(match_current).to eql(one_match.data['current'])
      expect(match_previous).to eql(one_match.data['previous'])

      expect(alert.data['items']).to include(two_item.id.to_s)
      item_data = alert.data['items'][two_item.id.to_s]
      expect(item_data).to include('matches')

      expect(item_data['matches']).to include(two_match.name)
      match_data = item_data['matches'][two_match.name]
      expect(match_data).to include({ 'match_id' => two_match.id })
      expect(match_data).to include('current')
      expect(match_data).to include('previous')

      match_current = match_data['current']
      match_previous = match_data['previous']
      expect(match_current).to eql(two_match.data['current'])
      expect(match_previous).to eql(two_match.data['previous'])
    end

    it 'should not create an alert if alert_creating switch is off' do
      client_data['data']['switches']['alerts']['creation'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(0)
    end

    it 'should create an alert if dispatch_alerts switch is off' do
      client_data['data']['switches']['alerts']['dispatch'] = false
      expect { subject.call }.to change { Service::Alert.all.size }.by(1)
    end
  end
end
