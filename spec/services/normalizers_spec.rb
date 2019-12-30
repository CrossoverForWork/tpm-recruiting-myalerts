require 'spec_helper'

describe 'Service::Normalizers' do
  let(:sample_data) do
    {
      'urlA' => {
        'message' => 'entry_added',
        'previous' => {
          'url' => 'urlA',
          'title' => 'titleA',
          'brand' => 'brandA',
          'msrp' => '40.00',
          'listed_price' => '32.50',
          'price' => '19.50',
          'status' => 'present'
        },
        'current' => {
          'url' => 'urlA',
          'title' => 'titleA',
          'brand' => 'brandA',
          'msrp' => '40.00',
          'listed_price' => '32.00',
          'price' => '19.00',
          'status' => 'present'
        },
        'current_record_digest' => '4c972afcab867223fecf36471dac61bf78c8737f',
        'previous_record_digest' => 'fa45f2f65bb7e49f0c7f487f60faac88e6a45699'
      },
      'urlB' => {
        'message' => 'entry_added',
        'previous' => {
          'url' => 'urlB',
          'title' => 'titleB',
          'brand' => 'brandB',
          'msrp' => '48.00',
          'listed_price' => '38.30',
          'price' => '22.30',
          'status' => 'present'
        },
        'current' => {
          'url' => 'urlB',
          'title' => 'titleB',
          'brand' => 'brandB',
          'msrp' => '48.00',
          'listed_price' => '38.00',
          'price' => '22.00',
          'status' => 'present'
        },
        'current_record_digest' => '4c972afcab867223fecf36471dac61bf78c8737f',
        'previous_record_digest' => 'fa45f2f65bb7e49f0c7f487f60faac88e6a45699'
      },
      'urlC' => {
        'message' => 'entry_added',
        'previous' => {
          'url' => 'urlC',
          'title' => 'titleC',
          'brand' => 'brandC',
          'msrp' => '44.00',
          'listed_price' => '34.00',
          'price' => '20.00',
          'status' => 'present'
        },
        'current' => {
          'url' => 'urlC',
          'title' => 'titleC',
          'brand' => 'brandC',
          'msrp' => '44.00',
          'listed_price' => '34.00',
          'price' => '20.00',
          'status' => 'present'
        },
        'current_record_digest' => '4c972afcab867223fecf36471dac61bf78c8737f',
        'previous_record_digest' => 'fa45f2f65bb7e49f0c7f487f60faac88e6a45699'
      },
      'urlD' => {
        'message' => 'entry_added',
        'previous' => {
          'url' => 'urlD',
          'title' => 'titleD',
          'brand' => 'brandD',
          'msrp' => '90.00',
          'listed_price' => '79.00',
          'price' => '47.40',
          'status' => 'present'
        },
        'current' => {
          'url' => 'urlD',
          'title' => 'titleD',
          'brand' => 'brandD',
          'msrp' => '90.00',
          'listed_price' => '79.00',
          'price' => '47.00',
          'status' => 'present'
        },
        'current_record_digest' => '4c972afcab867223fecf36471dac61bf78c8737f',
        'previous_record_digest' => 'fa45f2f65bb7e49f0c7f487f60faac88e6a45699'
      },
      'urlE' => {
        'message' => 'entry_added',
        'previous' => {
          'url' => 'urlE',
          'title' => 'titleE',
          'brand' => 'brandE',
          'msrp' => '450.00',
          'listed_price' => '395.00',
          'price' => '237.20',
          'status' => 'present'
        },
        'current' => {
          'url' => 'urlE',
          'title' => 'titleE',
          'brand' => 'brandE',
          'msrp' => '450.00',
          'listed_price' => '395.00',
          'price' => '237.00',
          'status' => 'present'
        },
        'current_record_digest' => '4c972afcab867223fecf36471dac61bf78c8737f',
        'previous_record_digest' => 'fa45f2f65bb7e49f0c7f487f60faac88e6a45699'
      }
    }
  end

  describe 'Base' do
    describe '.call' do
      it 'limits by price' do
        subject = Service::Normalizer::Base.new(sample_data)
        actual = subject.send(:call)

        expect(actual).to include({ 'urlE' => sample_data['urlE'] })
        expect(actual).to include({ 'urlD' => sample_data['urlD'] })
        expect(actual).to include({ 'urlB' => sample_data['urlB'] })
      end
    end
  end

  describe 'PriceChange' do
    describe '.call' do
      it 'limits by price change' do
        subject = Service::Normalizer::PriceChange.new(sample_data)
        actual = subject.send(:call)

        expect(actual).to include({ 'urlA' => sample_data['urlA'] })
        expect(actual).to include({ 'urlD' => sample_data['urlD'] })
        expect(actual).to include({ 'urlB' => sample_data['urlB'] })
      end
    end
  end

  describe 'RegistryPurchase' do
    describe '.call' do
      it 'limits by price and overrides limit' do
        subject = Service::Normalizer::RegistryPurchase.new(sample_data)
        actual = subject.send(:call)

        expect(actual).to include({ 'urlA' => sample_data['urlA'] })
        expect(actual).to include({ 'urlB' => sample_data['urlB'] })
        expect(actual).to include({ 'urlC' => sample_data['urlC'] })
        expect(actual).to include({ 'urlD' => sample_data['urlD'] })
        expect(actual).to include({ 'urlE' => sample_data['urlE'] })
      end
    end
  end
end
