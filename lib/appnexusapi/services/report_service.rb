module AppnexusApi
  class ReportService < AppnexusApi::Service
    REPORT_READY = 'ready'.freeze

    def initialize(connection)
      @read_only = false
      super(connection)
    end

    def report_meta_data(report_name)
      fail('Report name has to be defined!') if report_name.nil? || report_name.empty?

      meta_data = get('meta' => report_name)
      return nil if meta_data.nil?

      meta_data.first.raw_json
    end

    def download(id_hash, report_parameters)
      report_id = create(id_hash, report_parameters).raw_json

      # wait while report is ready
      loop do
        report_status = get('id' => report_id).first.raw_json
        break if report_status == REPORT_READY
        sleep(60)
      end

      report_results(report_id)
    end

    private

    def report_results(report_id)
      @connection.get('report-download', 'id' => report_id).body
    end

    def parse_response(response)
      key = resource_name(response)

      [AppnexusApi::Resource.new(response[key], self, response['dbg'])] unless key.nil? || key.empty?
    end

    def resource_name(response)
      %w(execution_status report_id report meta).detect { |n| response.key?(n) }
    end
  end
end
