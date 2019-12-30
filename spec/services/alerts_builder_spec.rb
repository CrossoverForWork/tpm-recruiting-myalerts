require 'spec_helper'

describe Service::AlertsBuilder do
  let(:alert_data) do
    {
      'items' => {}
    }
  end
  let(:alert_template) { 'template_1' }
  let(:client_data) do
    data = JSON.parse(File.read('./spec/fixtures/client_data.json'))['data']
    data['email_data'] = client_email_data
    data
  end
  let(:client_email_data) { JSON.parse(File.read('./spec/fixtures/client_data.json'))['data']['email_data'] }
  let(:client_identifier) { 'wldemo' }
  let(:notification) { 'email' }
  let(:user_identifier) { 'johndoe+0@example.com' }
  let(:uuid) { '8c96cfdc-3af0-4e2b-9bc8-704e8b005893' }

  let(:user) { FactoryGirl.create(:user, { client_identifier: client_identifier, user_identifier: user_identifier }) }
  let(:list) { FactoryGirl.create(:list) }
  let(:alert) do
    FactoryGirl.create(
      :alert_with_trackers,
      { data: alert_data,
        template: alert_template,
        user: user }
    )
  end

  let(:options) do
    {
      'alert_id' => alert.id,
      'uuid' => uuid,
      'notification' => notification,
      'client_data' => client_data
    }
  end

  let(:subject_options) do
    {
      alert: alert,
      client_data: client_data,
      recipient: user_identifier,
      uuid: uuid
    }
  end

  subject { Service::AlertsBuilder.new(options) }

  describe '.sqs_message_body' do
    shared_examples_for 'a default alert' do
      it 'includes basic fields' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_alert_id' => alert.id.to_s,
            'tpl_rules_engine' => 'erb',
            'ams_version' => 1,
            'service_url' => nil,
            'path' => '/',
            'method' => 'post',
            'ams_item_url' => nil }
        )

        expect(actual).to include('tpl_rules_engine_parameters')
        expect(actual['tpl_rules_engine_parameters']).to include('locals')

        actual_locals = actual['tpl_rules_engine_parameters']['locals']

        expect(actual_locals).to include(
          { 'logo_url' => true,
            'custom_css' => '',
            'registry_id' => nil }
        )

        expect(actual_locals).to include('items')
        expect(actual_locals['items']).to eql(alert_data['items'])
      end

      it 'uses alert.template' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'tpl_template_name' => alert.template }
        )
      end

      it 'uses user.client_identifier' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include('tpl_rules_engine_parameters')
        expect(actual['tpl_rules_engine_parameters']).to include('locals')

        expect(actual).to include(
          { 'tpl_client_identifier' => user.client_identifier,
            'ams_client_id' => user.client_identifier }
        )

        actual_locals = actual['tpl_rules_engine_parameters']['locals']
        expect(actual_locals).to include(
          { 'client_identifier' => user.client_identifier }
        )
      end

      it 'uses user.user_identifier' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_to' => user.user_identifier }
        )

        expect(actual).to include('tpl_rules_engine_parameters')
        expect(actual['tpl_rules_engine_parameters']).to include('locals')

        actual_locals = actual['tpl_rules_engine_parameters']['locals']

        expect(actual_locals).to include(
          { 'user_email' => CGI.escape(user_identifier) }
        )
      end

      it 'uses uuid' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include({ 'uuid' => uuid })
      end

      it 'uses client uuid' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include('tpl_rules_engine_parameters')
        expect(actual['tpl_rules_engine_parameters']).to include('locals')

        actual_locals = actual['tpl_rules_engine_parameters']['locals']

        expect(actual_locals).to include(
          { 'client_uuid' => client_data['uuid'] }
        )
      end

      it 'uses sendgrid credentials' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_sg_user' => client_data['sg_username'],
            'ams_sg_pass' => client_data['sg_password'] }
        )
      end

      it 'uses client email_data' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_from' => client_email_data['ams_from'],
            'ams_text' => client_email_data['ams_text'],
            'ams_fromname' => client_email_data['ams_fromname'],
            'ams_reply_to' => client_email_data['ams_reply_to'] }
        )
      end
    end

    context 'with product_availability_alert' do
      let(:alert_data) { JSON.parse(File.read('./spec/fixtures/product_availability_alert.json', { external_encoding: 'iso-8859-1' })) }

      it_behaves_like 'a default alert'

      it 'sends a valid sqs message' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_categories' => ['tracked-changes'],
            'ams_matches_list' => '',
            'ams_subject' => 'Back In Stock Alert: Acme Two' }
        )

        actual_locals = actual['tpl_rules_engine_parameters']['locals']
        expect(actual_locals['items']).to eql(alert_data['items'])
      end

      it 'returns a success message' do
        expect(subject.call).to eql(
          { 'status' => 'success',
            'uuid' => uuid,
            'email' => user_identifier,
            'message' => '' }
        )
      end
    end

    context 'with product_search alert type' do
      let(:alert_data) do
        {
          'items' => {
            '12345' => {
              'matches' => {
                'product_search_list_update' => {
                  'urlA' => {
                    'current' => {
                      'price' => '1000.00'
                    }
                  },
                  'urlB' => {
                    'current' => {
                      'price' => '2000.00'
                    }
                  }
                }
              }
            }
          }
        }
      end

      it_behaves_like 'a default alert'

      it 'sends a valid sqs message' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_categories' => ['tracked-changes'],
            'ams_matches_list' => '',
            'ams_subject' => 'Back In Stock Alert: Acme Two' }
        )

        actual_locals = actual['tpl_rules_engine_parameters']['locals']
        expect(actual_locals['items']).to eql(alert_data['items'])
      end

      it 'returns a success message' do
        expect(subject.call).to eql(
          { 'status' => 'success',
            'uuid' => uuid,
            'email' => user_identifier,
            'message' => '' }
        )
      end
    end

    context 'with custom alert template' do
      let(:alert_template) { 'foo_template' }

      it_behaves_like 'a default alert'

      it 'uses special categories and subject' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_categories' => ['tracked-changes'],
            'ams_subject' => 'Back In Stock Alert: Acme Two' }
        )
      end
    end

    context 'with now_tracking template' do
      let(:alert_template) { 'now_tracking' }

      it_behaves_like 'a default alert'

      it 'uses special categories and subject' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_categories' => ['now-tracking'],
            'ams_subject' => 'You are now tracking this product!' }
        )
      end
    end

    context 'with custom client_identifier' do
      let(:client_identifier) { 'foo_client' }

      it_behaves_like 'a default alert'
    end

    context 'with custom user_identifier' do
      let(:user_identifier) { 'foo_email' }

      it_behaves_like 'a default alert'
    end

    context 'with custom uuid' do
      let(:uuid) { 'foo_uuid' }

      it_behaves_like 'a default alert'
    end

    context 'with sendgrid credentials' do
      let(:client_data) do
        {
          'sg_username' => 'foo_user',
          'sg_password' => 'foo_pass',
          'email_data' => client_email_data
        }
      end

      it_behaves_like 'a default alert'
    end

    context 'with custom email_data' do
      let(:client_email_data) do
        {
          'ams_from' => 'foo_from',
          'ams_text' => 'foo_text',
          'ams_subject' => 'foo_subject',
          'ams_fromname' => 'foo_fromname',
          'ams_reply_to' => 'foo_reply'
        }
      end

      it_behaves_like 'a default alert'
    end

    context 'with alert matches' do
      it 'sets ams_matches_list' do
        fake_match_one = OpenStruct.new({ 'name' => 'match_abc' })
        fake_match_two = OpenStruct.new({ 'name' => 'match_def' })
        fake_alert = OpenStruct.new(
          { 'matches' => [fake_match_one, fake_match_two],
            'user' => alert.user,
            'data' => alert.data,
            'template' => alert.template,
            'trackers' => alert.trackers }
        )
        subject_options[:alert] = fake_alert

        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include({ 'ams_matches_list' => 'match_abc,match_def' })
      end
    end

    context 'with item_data override' do
      it 'uses ams_item_url' do
        subject_options[:item_data] = { 'item_url' => 'foo' }
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_categories' => ['tracked-changes'],
            'ams_matches_list' => '',
            'ams_subject' => 'Back In Stock Alert: Acme Two',
            'ams_item_url' => 'foo' }
        )
      end
    end

    context 'with item_id override' do
      let(:item_one) { FactoryGirl.create(:item, { url: 'urlA' }) }
      let(:item_two) { FactoryGirl.create(:item, { url: 'urlB' }) }
      let(:alert) do
        alert = FactoryGirl.create(
          :alert_with_trackers,
          { data: alert_data,
            template: alert_template,
            user: user,
            trackers_count: 2,
            trackers_items: [item_one, item_two] }
        )

        item_one.current_record.data['data']['title'] = 'ABC'
        item_one.current_record.save

        item_two.current_record.data['data']['title'] = 'DEF'
        item_two.current_record.save

        alert
      end
      let(:client_identifier) { 'foo' } # override client to trigger specific subject

      it 'sets item_key default' do
        actual = subject.send(:sqs_message_body, subject_options)
        actual_locals = actual['tpl_rules_engine_parameters']['locals']
        expect(actual_locals).to include({ 'item_key' => item_one.url })
      end

      it 'overrides item_key' do
        subject_options[:item_id] = item_two.id
        actual = subject.send(:sqs_message_body, subject_options)
        actual_locals = actual['tpl_rules_engine_parameters']['locals']
        expect(actual_locals).to include({ 'item_key' => item_two.url })
      end

      it 'uses first item title for subject' do
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_subject' => 'ABC has been updated' }
        )
      end

      it 'overrides item title for subject' do
        subject_options[:item_id] = item_two.id
        actual = subject.send(:sqs_message_body, subject_options)
        expect(actual).to include(
          { 'ams_subject' => 'DEF has been updated' }
        )
      end
    end

    context 'with registry item' do
      let(:item_one) { FactoryGirl.create(:item, { url: 'urlA?registryId=foobarzaz' }) }
      let(:alert) do
        FactoryGirl.create(
          :alert_with_trackers,
          { data: alert_data,
            template: alert_template,
            user: user,
            trackers_count: 1,
            trackers_items: [item_one] }
        )
      end

      it 'sets registry_id' do
        actual = subject.send(:sqs_message_body, subject_options)
        actual_locals = actual['tpl_rules_engine_parameters']['locals']
        expect(actual_locals).to include({ 'registry_id' => 'foobarzaz' })
      end
    end
  end

  describe '.call' do
    let(:alert_data) do
      {
        'items' => {
          'id001' => {
            'data001' => 'data001',
            'matches' => {}
          },
          'id002' => {
            'data002' => 'data002',
            'matches' => {}
          },
          'id003' => {
            'data003' => 'data003',
            'matches' => {}
          }
        }
      }
    end
    # alert used for init but not relevant to test
    let(:alert) do
      FactoryGirl.create(
        :alert_with_trackers,
        :product_availability_alert,
        { user: user,
          type: 'immediate' }
      )
    end

    context 'with immediate alert' do
      let(:fake_alert) { FactoryGirl.create(:alert, { user: user, type: 'immediate', data: alert_data }) }

      it 'should default to original recipent' do
        subject.instance_variable_set(:@alert, fake_alert)

        subject_options[:alert] = fake_alert
        subject_options[:recipient] = user.user_identifier
        expect(subject).to receive(:send_sqs_message).with(subject_options).once

        expect(subject.call).to eql(
          { 'message' => '',
            'status' => 'success',
            'uuid' => options['uuid'],
            'email' => alert.user.user_identifier }
        )
      end

      it 'with override enabled' do
        client_data['switches']['alerts']['recipient_override']['enabled'] = true
        subject.instance_variable_set(:@alert, fake_alert)

        subject_options[:alert] = fake_alert
        subject_options[:recipient] = 'rodrigo@myalerts.com'
        expect(subject).to receive(:send_sqs_message).with(subject_options).once

        expect(subject.call).to eql(
          { 'status' => 'success',
            'uuid' => '8c96cfdc-3af0-4e2b-9bc8-704e8b005893',
            'email' => ['rodrigo@myalerts.com'],
            'message' => '' }
        )
      end
    end

    context 'with registry alert' do
      let(:fake_alert) { FactoryGirl.create(:alert, { user: user, type: 'registry', data: alert_data }) }

      it 'should loop over items' do
        subject.instance_variable_set(:@alert, fake_alert)

        expect(subject).to receive(:send_sqs_message).with(
          { alert: fake_alert,
            recipient: user.user_identifier,
            item_id: 'id001',
            item_data: {
              'data001' => 'data001',
              'matches' => {}
            },
            client_data: client_data,
            uuid: uuid }
        ).once

        expect(subject).to receive(:send_sqs_message).with(
          { alert: fake_alert,
            recipient: user.user_identifier,
            item_id: 'id002',
            item_data: {
              'data002' => 'data002',
              'matches' => {}
            },
            client_data: client_data,
            uuid: uuid }
        ).once

        expect(subject).to receive(:send_sqs_message).with(
          { alert: fake_alert,
            recipient: user.user_identifier,
            item_id: 'id003',
            item_data: {
              'data003' => 'data003',
              'matches' => {}
            },
            client_data: client_data,
            uuid: uuid }
        ).once

        expect(subject.call).to eql(
          { 'message' => '',
            'status' => 'success',
            'uuid' => options['uuid'],
            'email' => alert.user.user_identifier }
        )
      end

      it 'should loop with overrides' do
        client_data['switches']['alerts']['recipient_override']['enabled'] = true

        subject.instance_variable_set(:@alert, fake_alert)

        expect(subject).to receive(:send_sqs_message).with(
          { alert: fake_alert,
            recipient: 'rodrigo@myalerts.com',
            item_id: 'id001',
            item_data: {
              'data001' => 'data001',
              'matches' => {}
            },
            client_data: client_data,
            uuid: uuid }
        ).once

        expect(subject).to receive(:send_sqs_message).with(
          { alert: fake_alert,
            recipient: 'rodrigo@myalerts.com',
            item_id: 'id002',
            item_data: {
              'data002' => 'data002',
              'matches' => {}
            },
            client_data: client_data,
            uuid: uuid }
        ).once

        expect(subject).to receive(:send_sqs_message).with(
          { alert: fake_alert,
            recipient: 'rodrigo@myalerts.com',
            item_id: 'id003',
            item_data: {
              'data003' => 'data003',
              'matches' => {}
            },
            client_data: client_data,
            uuid: uuid }
        ).once

        expect(subject.call).to eql(
          { 'message' => '',
            'status' => 'success',
            'uuid' => options['uuid'],
            'email' => ['rodrigo@myalerts.com'] }
        )
      end
    end
  end
end
