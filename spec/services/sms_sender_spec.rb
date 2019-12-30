describe 'SMS Sender' do
  let(:user) { FactoryGirl.create(:user) }
  let(:item) { FactoryGirl.create(:item) }

  let(:list) { FactoryGirl.create(:list) }
  let(:tracker) { FactoryGirl.create(:tracker, { item: item, list: list }) }

  let(:data_sms_alert) do
    {
      'alert_id' => alert.id,
      'notification' => 'sms',
      'client_data'  => 'stub',
      'uuid' => 'uuid_1234567890'
    }
  end

  context 'with product_availability alert' do
    let(:match) { FactoryGirl.create(:match, :product_availability, { tracker: tracker, user: user }) }
    let(:alert) { FactoryGirl.create(:alert, :price_drop, { user_id: user.id, matches: [match], trackers: [tracker], items: [item] }) }
    let(:data) { data_sms_alert }
    let(:sender) { ::Service::AlertSender.build(data) }
    let(:expected) do
      [
        {
          'notification' => data_sms_alert['notification'],
          'uuid'         => data_sms_alert['uuid'],

          'alert_id'          => alert.id.to_s,
          'alert_type'        => alert.type,
          'client_identifier' => user.client_identifier,
          'item_type'         => item.type,
          'items'             => [
            {
              'item_id'       => item.id.to_s,
              'item_url'      => item.url
            }
          ],
          'matches' => [
            {
              'match_name'    => match.name,
              'match_id'      => match.id.to_s,
              'item_url'      => match.data['url'],
              'item_title'    => match.data['current']['title']
            }
          ],
          'match_id'          => match.id.to_s,
          'match_types'       => alert.match_types,
          'tracker_id'        => tracker.id.to_s,
          'user_id'           => user.id.to_s,
          'user_identifier'   => user.user_identifier
          # TODO: 'user_phone'             => @user.phone
        }
      ]
    end

    it 'returns SmsSender' do
      expect(sender).to be_an_instance_of ::Service::SmsSender
    end

    it 'builds suitable payload' do
      allow(sender).to receive(:send_sns_message)
      expect(sender).to receive(:send_sns_message).with(expected)

      response = sender.call

      expect(response).to_not be_nil
      expect(response['status']).to eql('success')
    end

    describe '.normalize_phone' do
      [
        {
          name: 'allow proper format',
          original: '+15553214567',
          expected: '+15553214567'
        },
        {
          name: 'allow human format',
          original: '+1 (555) 321-4567',
          expected: '+15553214567'
        },
        {
          name: 'allow US phone',
          original: '(555) 321-4567',
          expected: '+15553214567'
        },
        {
          name: 'prepend +',
          original: '1 (555) 321-4567',
          expected: '+15553214567'
        },
        {
          name: 'do not prepend 1 if 10 numbers',
          original: '+5553214567',
          expected: '+5553214567'
        },
        {
          name: 'not prepend 1 if 9 numbers',
          original: '+553214567',
          expected: '+553214567'
        },
        {
          name: 'strip parens',
          original: '+1(555)3214567',
          expected: '+15553214567'
        },
        {
          name: 'strip whitespace',
          original: '+1 555 321 4567',
          expected: '+15553214567'
        },
        {
          name: 'strip hyphen',
          original: '+1-555-321-4567',
          expected: '+15553214567'
        },
        {
          name: 'strip period',
          original: '+1.555.321.4567',
          expected: '+15553214567'
        },
        {
          name: 'strip letters',
          original: '+1555321BEEF',
          expected: '+1555321BEEF'
        },
        {
          name: 'ignore short number',
          original: '321-4567',
          expected: '321-4567'
        },
        {
          name: 'ignore long number',
          original: '321-4567-89012',
          expected: '321-4567-89012'
        }
      ].each do |context|
        it 'should ' + context[:name] do
          actual = sender.send(:normalize_phone, context[:original])
          expect(actual).to eql(context[:expected])
        end
      end
    end
  end

  context 'with job_search_list_update alert' do
    let(:match) { FactoryGirl.create(:match, :job_search_list_update, { tracker: tracker, user: user }) }
    let(:alert) { FactoryGirl.create(:alert, :price_drop, { user_id: user.id, matches: [match], trackers: [tracker], items: [item] }) }
    let(:data) { data_sms_alert }
    let(:sender) { ::Service::AlertSender.build(data) }
    let(:expected) do
      [
        {
          'notification' => data_sms_alert['notification'],
          'uuid'         => data_sms_alert['uuid'],

          'alert_id'          => alert.id.to_s,
          'alert_type'        => alert.type,
          'client_identifier' => user.client_identifier,
          'item_type'         => item.type,
          'items'             => [
            {
              'item_id'           => item.id.to_s,
              'item_url'          => item.url
            }
          ],
          'matches' => [
            {
              'match_name'    => match.name,
              'match_id'      => match.id.to_s,
              'item_uuid'     => match.data.first[1]['item_uuid'],
              'item_url'      => match.data.first[0],
              'item_title'    => match.data.first[1]['current']['title'],
              'item_location' => match.data.first[1]['current']['location']
            }
          ],
          'match_id'          => match.id.to_s,
          'match_types'       => alert.match_types,
          'tracker_id'        => tracker.id.to_s,
          'user_id'           => user.id.to_s,
          'user_identifier'   => user.user_identifier
          # TODO: 'user_phone'             => @user.phone
        }
      ]
    end

    it 'builds suitable payload' do
      allow(sender).to receive(:send_sns_message)
      expect(sender).to receive(:send_sns_message).with(expected)

      response = sender.call

      expect(response).to_not be_nil
      expect(response['status']).to eql('success')
    end
  end
end
