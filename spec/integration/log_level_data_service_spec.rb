require 'spec_helper'

describe AppnexusApi::LogLevelDataService do
  it 'downloads new files' do
    VCR.use_cassette('log_level_data_service_download') do
      described_class.new(connection).download_new_files_since(Time.now - 7200)
    end
  end
end
