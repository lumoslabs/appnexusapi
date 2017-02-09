require "faraday"
require 'retriable'

require "appnexusapi/version"
require "appnexusapi/error"
require 'appnexusapi/resource'
require 'appnexusapi/service'
require 'appnexusapi/read_only_service'

module AppnexusApi
  autoload :Connection, "appnexusapi/connection"

  dir = File.join(File.dirname(__FILE__), 'appnexusapi')
  files = Dir.glob(File.expand_path("{*resource,*service}.rb", dir)).map { |f| File.join(dir, File.basename(f, '.rb')) }

  service_dir = File.join(dir, 'services')
  files += Dir.glob(File.expand_path("*service.rb", service_dir)).map { |f| File.join(service_dir, File.basename(f, '.rb')) }

  files.each do |file|
    require file
  end
end
