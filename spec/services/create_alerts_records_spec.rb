require 'spec_helper'

describe 'Service::AlertsGenerator.create_alerts_records' do
  let(:user)            { FactoryGirl.create(:user) }
  let(:list)            { FactoryGirl.create(:list) }
  let(:prev_record)     { FactoryGirl.create(:item_record, :removed_entry, { item_id: item.id, created_at: curr_record.created_at - 1_000 }) }
  let(:curr_record)     { FactoryGirl.create(:item_record, :present_entry, { item_id: item.id }) }

  let(:item)        { FactoryGirl.create(:item) }
  let(:tracker)     { FactoryGirl.create(:tracker, { item: item, list: list }) }
  let(:match)       { FactoryGirl.create(:match, :product_price_change, { tracker: tracker, user: user }) }

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
    let(:options)         do
      {
        'client_identifier' => 'wldemo',
        'user_id' => user.id,
        'trackers_ids' => [tracker.id],
        'requested_type' => alert_type,
        'requested_data' => requested_data
      }
    end
    let(:template_name) { client_data['data']['alerts']['matches'][match_name]['template'] }

    let(:alerts_data) do
      data = {}
      data[template_name] = {
        'match_types' => [match_name],
        'matches_ids' => [match.id],
        'trackers_ids' => [tracker.id],
        'alert_type' => alert_type,
        'items' => {},
        'notification_method' => 'email'
      }

      data[template_name]['items'][item.id] = {
        'tracker_id' => tracker.id,
        'item_id' => item.id,
        'item_uuid' => item.uuid,
        'item_url' => item.url,
        'notification_method' => 'email',
        'tracker' => {
          'meta' => tracker.meta,
          'created_at' => tracker.created_at
        },
        'item_current_record' => {
          'data' => curr_record.data,
          'digest' => curr_record.digest,
          'id' => curr_record.id
        },
        'matches' => {}
      }

      data[template_name]['items'][item.id]['matches'][match_name] = {
        'message' => match.data['message'],
        'url' => match.data['url'],
        'previous' => match.data['previous'],
        'previous_record_digest' => match.data['previous_record_digest'],
        'current' => match.data['current'],
        'current_record_digest' => match.data['current_record_digest'],
        'match_id' => match.id
      }

      {
        'template' => template_name,
        'data' => data[template_name],
        'user_id' => user.id,
        'notification_method' => 'email',
        'alert_type'   => data[template_name]['alert_type'],
        'match_types'  => data[template_name]['match_types'],
        'trackers_ids' => data[template_name]['trackers_ids'],
        'matches_ids'  => data[template_name]['matches_ids']
      }
    end

    subject { Service::AlertsGenerator.new(options) }

    it 'creates alert record' do
      actual_alert = subject.send(:create_alert_record, alerts_data)

      expect(actual_alert.template).to eql(template_name)
      expect(actual_alert.data).to eql(alerts_data['data'])
      expect(actual_alert.user_id).to eql(user.id)
      expect(actual_alert.type).to eql(alert_type)
      expect(actual_alert.match_types).to eql(match_name)

      expect(actual_alert.trackers.length).to eql(1)
      expect(actual_alert.trackers.first.id).to eql(tracker.id)

      expect(actual_alert.matches.length).to eql(1)
      expect(actual_alert.matches.first.id).to eql(match.id)
    end
  end
end
