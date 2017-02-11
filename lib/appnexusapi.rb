require 'faraday'
require 'faraday_middleware'
require 'retriable'

require 'appnexusapi/version'
require 'appnexusapi/error'
require 'appnexusapi/resource'
require 'appnexusapi/service'
require 'appnexusapi/read_only_service'
require 'appnexusapi/connection'

Dir.glob("#{File.join(File.dirname(__FILE__), 'appnexusapi', 'services')}/*.rb").each do |service_file|
  require service_file
end

module AppnexusApi
end
