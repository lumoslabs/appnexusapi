require 'spec_helper'

describe AppnexusApi::ReportService do
  include_context 'with an advertiser'

  let(:report_service) { described_class.new(connection) }
  let(:report_name) { 'advertiser_analytics' }

  context 'report metadata' do
    it 'supports report metadata' do
      VCR.use_cassette('report_service_metadata') do
        expect { report_service.report_meta_data(report_name) }.to_not raise_error
      end
    end

    it 'returns metadata hash' do
      VCR.use_cassette('report_service_metadata') do
        meta_data = report_service.report_meta_data(report_name)
        expect(meta_data).to be_a(Hash)
        expect(meta_data).to have_key('time_granularity')
        expect(meta_data).to have_key('columns')
        expect(meta_data).to have_key('filters')
        expect(meta_data).to have_key('time_intervals')
      end
    end
  end

  context 'report download' do
    let(:columns) { %w(day campaign_id advertiser_currency spend_adv_curr clicks imps) }
    let(:report_parameters) do
      {
        'format' => 'csv',
        'timezone' => 'UTC',
        'report_type' => report_name,
        'start_date' => '2018-01-15 00:00:00',
        'end_date' => '2018-01-16 00:00:00',
        'columns' => columns
      }
    end

    it 'returns a CSV string' do
      VCR.use_cassette('report_service_generate') do
        report = report_service.download(advertiser_url_params, report_parameters)
        expect(report).to be_a(String)
        expect(report).to include(columns.join(','))
      end
    end
  end
end
