require 'spec_helper'

describe AppnexusApi::Connection do
  let(:connection_with_null_logger) { AppnexusApi::Connection.new(connection_params) }

  subject do
    connection = described_class.new({})
    connection.logger.level = Logger::FATAL
    connection
  end

  it 'allows no logger to be specified' do
    expect { AppnexusApi::CreativeService.new(connection_with_null_logger) }.to_not raise_error
  end

  context 'retries' do
    let(:reponse_data) { { not_an_error: 1 } }

    it 'returns data from expiration' do
      #stub to raise error the first time and then return []
      counter = 0
      expect(subject).to receive(:login)
      expect(subject.connection).to receive(:run_request).twice do |arg|
        counter += 1
        raise AppnexusApi::Unauthorized.new if counter == 1
        Faraday::Response.new(body: reponse_data)
      end

      expect(subject.get('http://localhost', {}, {}).body).to eq(reponse_data)
    end

    context 'rate limited errors' do
      let(:response) do
        Faraday::Response.new(
          body: { 'error_code' => described_class::RATE_EXCEEDED_DEFAULT_TIMEOUT },
          response_headers: { 'retry-after' => 15 }
        )
      end

      it 'retries 3 times' do
        counter = 0
        expect(subject).to receive(:login)
        expect(subject.connection).to receive(:run_request).twice do |arg|
          puts response.pretty_inspect
          counter += 1
          counter <= 2 ? response : Faraday::Response.new(body: reponse_data)
        end
        puts "counter is #{counter}"
        expect(subject.get('http://localhost', {}, {}).body).to eq(reponse_data)
      end
    end
  end
end
