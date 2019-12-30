require 'spec_helper'

describe 'Service::AlertsGenerator.build_alerts_data' do
  let(:user)            { FactoryGirl.create(:user) }
  let(:list)            { FactoryGirl.create(:list) }
  let(:prev_record)     { FactoryGirl.create(:item_record, :removed_entry, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
  let(:curr_record)     { FactoryGirl.create(:item_record, :present_entry, { item_id: item.id }) }

  let(:item)        { FactoryGirl.create(:item) }
  let(:tracker)     { FactoryGirl.create(:tracker, { item: item, list: list }) }
  let(:match)       { FactoryGirl.create(:match, :product_price_change, { tracker: tracker, user: user }) }
  let(:matches)     { [match] }

  let(:client_data) { JSON.parse(File.read('./spec/fixtures/client_data.json')) }

  before do
    allow_any_instance_of(::Service::ClientReader).to receive(:call) { client_data }
    curr_record # HACK
    prev_record # HACK
    match # HACK
  end

  context 'with product_price_change match' do
    let(:alert_type)  { 'product' }
    let(:match_name)  { 'product_price_change' }
    let(:requested_data)  { ['matches'] }
    let(:template_name) { client_data['data']['alerts']['matches'][match_name]['template'] }
    let(:options)         do
      {
        'client_identifier' => 'wldemo',
        'user_id' => user.id,
        'trackers_ids' => [tracker.id],
        'requested_type' => alert_type,
        'requested_data' => requested_data
      }
    end

    subject { Service::AlertsGenerator.new(options) }

    it 'builds alerts data' do
      matches = subject.send(:get_matches, [tracker.id], false)
      subject.instance_variable_set(:@matches, matches)
      alert_data = subject.send(:build_alerts_data)

      expect(alert_data.length).to eql(1)

      alert = alert_data.first
      expect(alert).to include({ 'template' => template_name,
                                 'user_id' => user.id })

      expect(alert['data']).to include({ 'match_types' => [match_name] })
      expect(alert['data']).to include({ 'matches_ids' => [match.id] })
      expect(alert['data']).to include({ 'trackers_ids' => [tracker.id] })
      expect(alert['data']).to include({ 'alert_type' => alert_type })
      expect(alert['data']).to include({ 'notification_method' => tracker.notification_methods.first })

      expect(alert['data']['items']).to include(item.id)
      item_data = alert['data']['items'][item.id]

      expect(item_data).to include({ 'tracker_id' => tracker.id })
      expect(item_data).to include({ 'item_id' => item.id })
      expect(item_data).to include({ 'item_uuid' => item.uuid })
      expect(item_data).to include({ 'item_url' => item.url })

      expect(item_data).to include({ 'tracker' => {
        'meta' => tracker.meta,
        'created_at' => tracker.created_at
      } })
      expect(item_data).to include({ 'item_current_record' => {
        'data' => curr_record.data,
        'digest' => curr_record.digest,
        'id' => curr_record.id
      } })

      expect(item_data['matches']).to include(match_name)
      match_data = item_data['matches'][match_name]

      expect(match_data).to include({ 'message' => match.data['message'] })
      expect(match_data).to include({ 'url' => match.data['url'] })
      expect(match_data).to include({ 'previous' => match.data['previous'] })
      expect(match_data).to include({ 'previous_record_digest' => match.data['previous_record_digest'] })
      expect(match_data).to include({ 'current' => match.data['current'] })
      expect(match_data).to include({ 'current_record_digest' => match.data['current_record_digest'] })
      expect(match_data).to include({ 'match_id' => match.id })
    end
  end

  context 'with now_tracking alert' do
    let(:alert_type)  { 'product' }
    let(:match_name)  { 'now_tracking' }
    let(:requested_data)  { ['now_tracking'] }
    let(:template_name) { client_data['data']['alerts']['matches'][match_name]['template'] }
    let(:options)         do
      {
        'client_identifier' => 'wldemo',
        'user_id' => user.id,
        'trackers_ids' => [tracker.id],
        'requested_type' => alert_type,
        'requested_data' => requested_data
      }
    end

    subject { Service::AlertsGenerator.new(options) }

    it 'builds alerts data' do
      matches = subject.send(:get_matches, [tracker.id], false)
      subject.instance_variable_set(:@matches, matches)
      alert_data = subject.send(:build_alerts_data)

      expect(alert_data.length).to eql(1)

      alert = alert_data.first
      expect(alert).to include({ 'template' => template_name,
                                 'user_id' => user.id })

      expect(alert['data']).to include({ 'match_types' => [match_name] })
      expect(alert['data']).to include({ 'matches_ids' => [] })
      expect(alert['data']).to include({ 'trackers_ids' => [tracker.id] })
      expect(alert['data']).to include({ 'alert_type' => alert_type })
      expect(alert['data']).to include({ 'notification_method' => tracker.notification_methods.first })

      expect(alert['data']['items']).to include(item.id)
      item_data = alert['data']['items'][item.id]

      expect(item_data).to include({ 'tracker_id' => tracker.id })
      expect(item_data).to include({ 'item_id' => item.id })
      expect(item_data).to include({ 'item_uuid' => item.uuid })
      expect(item_data).to include({ 'item_url' => item.url })

      expect(item_data).to include({ 'tracker' => {
        'meta' => tracker.meta,
        'created_at' => tracker.created_at
      } })
      expect(item_data).to include({ 'item_current_record' => {
        'data' => curr_record.data,
        'digest' => curr_record.digest,
        'id' => curr_record.id
      } })

      expect(item_data['matches']).to include(match_name)
      match_data = item_data['matches'][match_name]
      expect(match_data).to eql({})
    end
  end

  context 'with new_account alert' do
    let(:alert_type)  { 'product' }
    let(:match_name)  { 'new_account' }
    let(:requested_data)  { ['new_account'] }
    let(:template_name) { client_data['data']['alerts']['matches'][match_name]['template'] }
    let(:options)         do
      {
        'client_identifier' => 'wldemo',
        'user_id' => user.id,
        'trackers_ids' => [tracker.id],
        'requested_type' => alert_type,
        'requested_data' => requested_data
      }
    end

    subject { Service::AlertsGenerator.new(options) }

    it 'builds alerts data' do
      matches = subject.send(:get_matches, [tracker.id], false)
      subject.instance_variable_set(:@matches, matches)
      alert_data = subject.send(:build_alerts_data)

      expect(alert_data.length).to eql(1)

      alert = alert_data.first
      expect(alert).to include({ 'template' => template_name,
                                 'user_id' => user.id })

      expect(alert['data']).to include({ 'match_types' => [match_name] })
      expect(alert['data']).to include({ 'matches_ids' => [] })
      expect(alert['data']).to include({ 'trackers_ids' => [tracker.id] })
      expect(alert['data']).to include({ 'alert_type' => alert_type })
      expect(alert['data']).to include({ 'notification_method' => tracker.notification_methods.first })

      expect(alert['data']['items']).to include(item.id)
      item_data = alert['data']['items'][item.id]

      expect(item_data).to include({ 'tracker_id' => tracker.id })
      expect(item_data).to include({ 'item_id' => item.id })
      expect(item_data).to include({ 'item_uuid' => item.uuid })
      expect(item_data).to include({ 'item_url' => item.url })

      expect(item_data).to include({ 'tracker' => {
        'meta' => tracker.meta,
        'created_at' => tracker.created_at
      } })
      expect(item_data).to include({ 'item_current_record' => {
        'data' => curr_record.data,
        'digest' => curr_record.digest,
        'id' => curr_record.id
      } })

      expect(item_data['matches']).to include(match_name)
      match_data = item_data['matches'][match_name]
      expect(match_data).to eql({})
    end
  end
end
